//
//  AuthManager.swift
//  VirtualUAVHanger
//
//  Central auth state for Sign in with Apple, Google OAuth 2.0 (PKCE),
//  and local email/password (hashed, stored in UserDefaults).
//
//  Google setup:
//    1. Create an "iOS" OAuth client at console.cloud.google.com
//    2. Add GOOGLE_CLIENT_ID = <your-client-id> to the scheme's Environment Variables
//       (Edit Scheme → Run → Arguments → Environment Variables)
//
//  Sign in with Apple setup:
//    Enable the "Sign in with Apple" capability in Xcode →
//    target → Signing & Capabilities → + Capability → Sign in with Apple.
//

import AuthenticationServices
import Combine
import CryptoKit
import Foundation
import SwiftUI

// MARK: - AuthManager

@MainActor
final class AuthManager: NSObject, ObservableObject {

    // MARK: Published State

    @Published var isAuthenticated = false
    @Published var currentUser: UserSession?
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: Private

    private let sessionKey   = "vhangar.session"
    private var googleWebSession: ASWebAuthenticationSession?
    private var codeVerifier: String?

    // MARK: Init

    override init() {
        super.init()
        restoreSession()
    }

    // MARK: - Session Persistence

    private func restoreSession() {
        guard
            let data = UserDefaults.standard.data(forKey: sessionKey),
            let session = try? JSONDecoder().decode(UserSession.self, from: data)
        else { return }
        currentUser = session
        isAuthenticated = true
    }

    private func persist(_ session: UserSession) {
        currentUser = session
        isAuthenticated = true
        if let data = try? JSONEncoder().encode(session) {
            UserDefaults.standard.set(data, forKey: sessionKey)
        }
    }

    func signOut() {
        currentUser = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: sessionKey)
        errorMessage = nil
    }

    // MARK: - Sign in with Apple

    /// Called by `SignInWithAppleButton` to configure the authorization request.
    func handleAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }

    /// Called by `SignInWithAppleButton` when the user completes or cancels auth.
    func handleAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else { return }
            let nameParts = [credential.fullName?.givenName, credential.fullName?.familyName]
                .compactMap { $0 }
            let fullName = nameParts.joined(separator: " ")
            persist(UserSession(
                id: credential.user,
                name: fullName.isEmpty ? nil : fullName,
                email: credential.email,
                provider: .apple
            ))

        case .failure(let error):
            // Ignore user-initiated cancellation
            if (error as? ASAuthorizationError)?.code == .canceled { return }
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Google OAuth 2.0 with PKCE

    func signInWithGoogle() {
        let clientID = ProcessInfo.processInfo.environment["GOOGLE_CLIENT_ID"] ?? ""
        guard !clientID.isEmpty else {
            errorMessage = "Google Sign-In is not configured.\nAdd GOOGLE_CLIENT_ID to your scheme's environment variables."
            return
        }

        // PKCE – RFC 7636
        let verifier  = makeCodeVerifier()
        let challenge = makeCodeChallenge(from: verifier)
        codeVerifier  = verifier

        let redirectScheme = "com.googleusercontent.apps.\(clientID)"
        let redirectURI    = "\(redirectScheme):/oauth2callback"

        var comps = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        comps.queryItems = [
            .init(name: "client_id",             value: clientID),
            .init(name: "redirect_uri",           value: redirectURI),
            .init(name: "response_type",          value: "code"),
            .init(name: "scope",                  value: "openid email profile"),
            .init(name: "code_challenge",         value: challenge),
            .init(name: "code_challenge_method",  value: "S256"),
        ]
        guard let authURL = comps.url else { return }

        isLoading = true
        let session = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: redirectScheme
        ) { [weak self] callbackURL, error in
            Task { @MainActor [weak self] in
                self?.isLoading = false
                if let error {
                    if (error as? ASWebAuthenticationSessionError)?.code != .canceledLogin {
                        self?.errorMessage = error.localizedDescription
                    }
                    return
                }
                guard
                    let callbackURL,
                    let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
                        .queryItems?.first(where: { $0.name == "code" })?.value,
                    let verifier = self?.codeVerifier
                else { return }

                await self?.exchangeGoogleCode(
                    code: code,
                    verifier: verifier,
                    clientID: clientID,
                    redirectURI: redirectURI
                )
            }
        }
        session.presentationContextProvider = self
        session.prefersEphemeralWebBrowserSession = false
        session.start()
        googleWebSession = session
    }

    private func exchangeGoogleCode(
        code: String,
        verifier: String,
        clientID: String,
        redirectURI: String
    ) async {
        var req = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let encodedURI = redirectURI
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? redirectURI
        req.httpBody =
            "code=\(code)&client_id=\(clientID)&redirect_uri=\(encodedURI)"
            .appending("&grant_type=authorization_code&code_verifier=\(verifier)")
            .data(using: .utf8)

        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            guard
                let json     = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let idToken  = json["id_token"] as? String
            else {
                errorMessage = "Google Sign-In failed: unexpected server response."
                return
            }
            persist(parseJWTPayload(idToken, provider: .google))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Email / Password (local)

    /// Signs in or registers with a local email/password.
    /// The password is stored only as a SHA-256 hex hash — no plaintext ever written to disk.
    func signInWithEmail(email: String, password: String) {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard trimmedEmail.contains("@"), trimmedEmail.contains("."), password.count >= 6 else {
            errorMessage = "Enter a valid email and a password of at least 6 characters."
            return
        }

        let hashKey = "vhangar.pw.\(trimmedEmail)"
        let hash    = sha256Hex(password)

        if let stored = UserDefaults.standard.string(forKey: hashKey) {
            guard stored == hash else {
                errorMessage = "Incorrect password. Try again."
                return
            }
        } else {
            // First time with this email — register locally.
            UserDefaults.standard.set(hash, forKey: hashKey)
        }

        persist(UserSession(id: trimmedEmail, name: nil, email: email, provider: .email))
    }

    // MARK: - PKCE Helpers

    private func makeCodeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private func makeCodeChallenge(from verifier: String) -> String {
        Data(SHA256.hash(data: Data(verifier.utf8)))
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private func sha256Hex(_ string: String) -> String {
        SHA256.hash(data: Data(string.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }

    // MARK: - JWT ID Token Parser

    private func parseJWTPayload(_ token: String, provider: AuthProvider) -> UserSession {
        let parts = token.split(separator: ".")
        guard
            parts.count >= 2,
            let payloadData = base64URLDecode(String(parts[1])),
            let json = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any]
        else {
            return UserSession(id: UUID().uuidString, name: nil, email: nil, provider: provider)
        }
        return UserSession(
            id:       json["sub"]   as? String ?? UUID().uuidString,
            name:     json["name"]  as? String,
            email:    json["email"] as? String,
            provider: provider
        )
    }

    private func base64URLDecode(_ string: String) -> Data? {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = base64.count % 4
        if remainder > 0 { base64 += String(repeating: "=", count: 4 - remainder) }
        return Data(base64Encoded: base64)
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension AuthManager: ASWebAuthenticationPresentationContextProviding {
    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            #if os(iOS)
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow } ?? ASPresentationAnchor()
            #else
            NSApplication.shared.keyWindow ?? ASPresentationAnchor()
            #endif
        }
    }
}
