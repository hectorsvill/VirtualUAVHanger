//
//  LoginView.swift
//  VirtualUAVHanger
//
//  Full-screen login with Sign in with Apple, Google, and Email.
//

import AuthenticationServices
import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var auth: AuthManager
    @State private var showEmailSignIn = false

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                hero
                    .padding(.top, 100)

                Spacer()

                authCard
                    .padding(.horizontal, 24)
                    .padding(.bottom, 52)
            }
        }
        .ignoresSafeArea()
        // Error banner slides down from top
        .overlay(alignment: .top) {
            if let msg = auth.errorMessage {
                ErrorBanner(message: msg) { auth.errorMessage = nil }
                    .padding(.top, 56)
                    .padding(.horizontal, 20)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: auth.errorMessage)
        // Loading overlay
        .overlay {
            if auth.isLoading { LoadingOverlay() }
        }
        .sheet(isPresented: $showEmailSignIn) {
            EmailSignInView()
                .environmentObject(auth)
        }
    }

    // MARK: - Background

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.06, blue: 0.16),
                    Color(red: 0.02, green: 0.02, blue: 0.09),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Subtle radial glow behind hero icon
            RadialGradient(
                colors: [Color.blue.opacity(0.18), .clear],
                center: .top,
                startRadius: 10,
                endRadius: 380
            )
        }
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.25),
                                Color.purple.opacity(0.18),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 130, height: 130)

                Image(systemName: "airplane.circle.fill")
                    .font(.system(size: 76))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color.blue.opacity(0.75)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            VStack(spacing: 8) {
                Text("Virtual UAV Hangar")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                Text("Your FPV fleet, organized.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
    }

    // MARK: - Auth Buttons

    private var authCard: some View {
        VStack(spacing: 14) {

            // ── Sign in with Apple ──────────────────────────────
            SignInWithAppleButton(.signIn) { request in
                auth.handleAppleRequest(request)
            } onCompletion: { result in
                auth.handleAppleCompletion(result)
            }
            .signInWithAppleButtonStyle(.white)
            .frame(height: 52)
            .cornerRadius(14)

            // ── Google ──────────────────────────────────────────
            Button { auth.signInWithGoogle() } label: {
                HStack(spacing: 10) {
                    GoogleGlyph()
                    Text("Continue with Google")
                        .font(.system(size: 17, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.white)
                .foregroundStyle(Color(red: 0.22, green: 0.22, blue: 0.22))
                .cornerRadius(14)
            }

            orDivider

            // ── Email ───────────────────────────────────────────
            Button { showEmailSignIn = true } label: {
                HStack(spacing: 10) {
                    Image(systemName: "envelope.fill")
                    Text("Continue with Email")
                        .font(.system(size: 17, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.white.opacity(0.1))
                .foregroundStyle(.white)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            }

            Text("By continuing you agree to our Terms of Service.")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.3))
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
    }

    private var orDivider: some View {
        HStack(spacing: 12) {
            Rectangle().fill(Color.white.opacity(0.2)).frame(height: 1)
            Text("or")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.4))
            Rectangle().fill(Color.white.opacity(0.2)).frame(height: 1)
        }
    }
}

// MARK: - Google "G" Glyph

private struct GoogleGlyph: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 24, height: 24)

            // Four-colour "G" split into quadrants via a clipping mask trick
            Text("G")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        stops: [
                            .init(color: .blue,   location: 0.0),
                            .init(color: .red,    location: 0.33),
                            .init(color: .yellow, location: 0.66),
                            .init(color: .green,  location: 1.0),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .frame(width: 24, height: 24)
    }
}

// MARK: - Error Banner

private struct ErrorBanner: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)

            Text(message)
                .font(.footnote)
                .foregroundStyle(.white)
                .lineLimit(3)

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(red: 0.7, green: 0.1, blue: 0.1).opacity(0.9))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
    }
}

// MARK: - Loading Overlay

private struct LoadingOverlay: View {
    var body: some View {
        Color.black.opacity(0.45)
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: 14) {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.4)
                    Text("Signing in…")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(28)
                .background(.ultraThinMaterial)
                .cornerRadius(16)
            }
    }
}

// MARK: - Preview

#Preview {
    LoginView()
        .environmentObject(AuthManager())
}
