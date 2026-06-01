// LoginView.swift
// Markeet — Login screen with premium purple design

import AuthenticationServices
import CryptoKit
import FirebaseAuth
import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var viewModel = AuthViewModel()
    @State private var showingRegister    = false
    @State private var showingForgotPwd   = false
    @State private var showPassword       = false
    @State private var currentNonce: String?

    var body: some View {
        ZStack {
            // ── Background ───────────────────────────────────
            VStack(spacing: 0) {
                AppTheme.heroGradient
                    .frame(height: UIScreen.main.bounds.height * 0.42)
                Color(hex: "F2F2F7")
            }
            .ignoresSafeArea()

            // ── Content ──────────────────────────────────────
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // Hero section
                    VStack(spacing: 12) {
                        Image(systemName: "chart.bar.xaxis.ascending")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundColor(.white)
                            .padding(18)
                            .background(.white.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 20))

                        Text("Markeet")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)

                        Text("Komunitas Marketing Digital Indonesia")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.top, 70)
                    .padding(.bottom, 44)

                    // Card
                    VStack(spacing: 0) {
                        VStack(spacing: AppTheme.Spacing.lg) {

                            // Header
                            VStack(spacing: 6) {
                                Text("Selamat Datang!")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(AppTheme.textPrimary)

                                Text("Masuk untuk melanjutkan")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                            .padding(.top, 28)

                            // Fields
                            VStack(spacing: AppTheme.Spacing.md) {
                                fieldView(
                                    icon: "envelope.fill",
                                    placeholder: "Email",
                                    text: $viewModel.email,
                                    keyboard: .emailAddress
                                )

                                passwordFieldView(
                                    icon: "lock.fill",
                                    placeholder: "Password",
                                    text: $viewModel.password,
                                    isVisible: $showPassword
                                )
                            }

                            // Forgot Password
                            HStack {
                                Spacer()
                                Button("Lupa Password?") {
                                    showingForgotPwd = true
                                }
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppTheme.primary)
                            }

                            // Error
                            if let error = viewModel.errorMessage {
                                errorBanner(error)
                            }

                            // Login Button
                            Button {
                                Task { await viewModel.login(session: session) }
                            } label: {
                                Group {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Masuk")
                                    }
                                }
                                .primaryButton()
                            }
                            .disabled(viewModel.isLoading)

                            // Divider
                            HStack {
                                Rectangle().fill(AppTheme.divider).frame(height: 1)
                                Text("atau")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.textTertiary)
                                    .padding(.horizontal, 8)
                                Rectangle().fill(AppTheme.divider).frame(height: 1)
                            }

                            // Apple Sign-In
                            SignInWithAppleButton(.signIn) { request in
                                handleAppleRequest(request)
                            } onCompletion: { result in
                                Task { await handleAppleCompletion(result) }
                            }
                            .signInWithAppleButtonStyle(.black)
                            .frame(height: 50)
                            .cornerRadius(AppTheme.Radius.md)


                            // Register link
                            HStack(spacing: 4) {
                                Text("Belum punya akun?")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.textSecondary)
                                Button("Daftar sekarang") {
                                    showingRegister = true
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppTheme.primary)
                            }
                            .padding(.bottom, 8)
                        }
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .padding(.bottom, 32)
                    }
                    .background(Color(hex: "F2F2F7"))
                    .cornerRadius(28, corners: [.topLeft, .topRight])
                }
            }
        }
        .ignoresSafeArea(.keyboard)
        .onTapGesture { hideKeyboard() }
        .sheet(isPresented: $showingRegister) {
            RegisterView().environmentObject(session)
        }
        .sheet(isPresented: $showingForgotPwd) {
            ForgotPasswordView()
        }
    }

    // MARK: - Sub-views
    private func fieldView(icon: String, placeholder: String, text: Binding<String>, keyboard: UIKeyboardType) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(AppTheme.textTertiary)
                .frame(width: 20)
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .font(.system(size: 15))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(AppTheme.surface)
        .cornerRadius(AppTheme.Radius.sm)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.sm).stroke(AppTheme.divider))
    }

    private func passwordFieldView(icon: String, placeholder: String, text: Binding<String>, isVisible: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(AppTheme.textTertiary)
                .frame(width: 20)
            if isVisible.wrappedValue {
                TextField(placeholder, text: text)
                    .autocapitalization(.none)
                    .font(.system(size: 15))
            } else {
                SecureField(placeholder, text: text)
                    .font(.system(size: 15))
            }
            Button { isVisible.wrappedValue.toggle() } label: {
                Image(systemName: isVisible.wrappedValue ? "eye.slash" : "eye")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textTertiary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(AppTheme.surface)
        .cornerRadius(AppTheme.Radius.sm)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.sm).stroke(AppTheme.divider))
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(AppTheme.error)
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(AppTheme.error)
            Spacer()
        }
        .padding(12)
        .background(AppTheme.error.opacity(0.08))
        .cornerRadius(AppTheme.Radius.sm)
    }

    // MARK: - Apple Sign-In Logic
    private func handleAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    private func handleAppleCompletion(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let auth):
            guard
                let appleCredential = auth.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = appleCredential.identityToken,
                let idToken = String(data: tokenData, encoding: .utf8),
                let nonce = currentNonce
            else {
                viewModel.errorMessage = "Apple Sign-In gagal. Coba lagi."
                return
            }
            let credential = OAuthProvider.appleCredential(
                withIDToken: idToken,
                rawNonce: nonce,
                fullName: appleCredential.fullName
            )
            do {
                viewModel.isLoading = true
                _ = try await AuthService.shared.signInWithApple(credential: credential)
                await session.reloadCurrentUser()
            } catch {
                viewModel.errorMessage = error.localizedDescription
            }
            viewModel.isLoading = false

        case .failure(let error):
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                viewModel.errorMessage = error.localizedDescription
            }
        }
    }

    private func randomNonceString(length: Int = 32) -> String {
        var randomBytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Corner Radius Helper
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    LoginView().environmentObject(SessionManager())
}
