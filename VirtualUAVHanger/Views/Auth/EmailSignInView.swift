//
//  EmailSignInView.swift
//  VirtualUAVHanger
//
//  Modal sheet for email + password sign-in / first-time registration.
//  Passwords are never stored in plaintext — only a SHA-256 hex hash.
//

import SwiftUI

struct EmailSignInView: View {
    @EnvironmentObject private var auth: AuthManager
    @Environment(\.dismiss) private var dismiss

    @State private var email    = ""
    @State private var password = ""
    @State private var showPassword = false

    @FocusState private var focused: Field?

    private enum Field { case email, password }

    var canSubmit: Bool {
        email.contains("@") && password.count >= 6
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.07, blue: 0.16)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        headerIcon
                        formFields
                        if let error = auth.errorMessage {
                            errorLabel(error)
                        }
                        submitButton
                        hint
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Sign in with Email")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        auth.errorMessage = nil
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
        }
        .onDisappear { auth.errorMessage = nil }
    }

    // MARK: - Header

    private var headerIcon: some View {
        VStack(spacing: 12) {
            Image(systemName: "envelope.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Enter your email and choose a password.\nNew accounts are created automatically.")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Form Fields

    private var formFields: some View {
        VStack(spacing: 16) {
            fieldRow(
                label: "Email",
                icon: "envelope.fill"
            ) {
                TextField("you@example.com", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .focused($focused, equals: .email)
                    .submitLabel(.next)
                    .onSubmit { focused = .password }
                    .foregroundStyle(.white)
                    .tint(.blue)
                    .accessibilityIdentifier("field_email")
            } isFocused: { focused == .email }

            fieldRow(
                label: "Password",
                icon: "lock.fill"
            ) {
                Group {
                    if showPassword {
                        TextField("6+ characters", text: $password)
                            .accessibilityIdentifier("field_password")
                    } else {
                        SecureField("6+ characters", text: $password)
                            .accessibilityIdentifier("field_password")
                    }
                }
                .textContentType(.password)
                .focused($focused, equals: .password)
                .submitLabel(.done)
                .onSubmit(attemptSignIn)
                .foregroundStyle(.white)
                .tint(.blue)
            } isFocused: { focused == .password } trailing: {
                Button {
                    showPassword.toggle()
                } label: {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .foregroundStyle(.white.opacity(0.45))
                }
            }
        }
    }

    /// Generic styled field row.
    @ViewBuilder
    private func fieldRow<Content: View, Trailing: View>(
        label: String,
        icon: String,
        @ViewBuilder content: @escaping () -> Content,
        isFocused: @escaping () -> Bool,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.white.opacity(0.6))

            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundStyle(.white.opacity(0.35))
                    .frame(width: 18)

                content()

                trailing()
            }
            .padding(14)
            .background(Color.white.opacity(0.08))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isFocused()
                        ? Color.blue.opacity(0.65)
                        : Color.white.opacity(0.12),
                        lineWidth: 1
                    )
            )
            .animation(.easeInOut(duration: 0.15), value: isFocused())
        }
    }

    // Overload without trailing view
    @ViewBuilder
    private func fieldRow<Content: View>(
        label: String,
        icon: String,
        @ViewBuilder content: @escaping () -> Content,
        isFocused: @escaping () -> Bool
    ) -> some View {
        fieldRow(label: label, icon: icon, content: content, isFocused: isFocused) {
            EmptyView()
        }
    }

    // MARK: - Error Label

    private func errorLabel(_ message: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.footnote)
                .foregroundStyle(.red.mix(with: .orange, by: 0.3))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Submit Button

    private var submitButton: some View {
        Button(action: attemptSignIn) {
            Text("Continue")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    canSubmit
                    ? AnyShapeStyle(
                        LinearGradient(
                            colors: [.blue, Color(red: 0.5, green: 0.2, blue: 0.9)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    : AnyShapeStyle(Color.white.opacity(0.1))
                )
                .foregroundStyle(.white)
                .cornerRadius(14)
        }
        .disabled(!canSubmit)
        .animation(.easeInOut(duration: 0.2), value: canSubmit)
        .accessibilityIdentifier("btn_email_continue")
    }

    // MARK: - Hint

    private var hint: some View {
        Text("New to vHangar? Just enter an email and password — your account is created automatically.")
            .font(.caption)
            .foregroundStyle(.white.opacity(0.35))
            .multilineTextAlignment(.center)
    }

    // MARK: - Action

    private func attemptSignIn() {
        focused = nil
        auth.errorMessage = nil
        auth.signInWithEmail(email: email, password: password)
        if auth.isAuthenticated { dismiss() }
    }
}

// MARK: - Preview

#Preview {
    EmailSignInView()
        .environmentObject(AuthManager())
}
