// RegisterView.swift
// Markeet — Premium registration screen

import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: SessionManager
    @StateObject private var viewModel = AuthViewModel()
    @State private var showPassword        = false
    @State private var showConfirmPassword = false

    var body: some View {
        NavigationStack {
            ZStack {
                // ── Background ───────────────────────────────
                VStack(spacing: 0) {
                    AppTheme.heroGradient
                        .frame(height: UIScreen.main.bounds.height * 0.30)
                    Color(hex: "F2F2F7")
                }
                .ignoresSafeArea()

                // ── Content ──────────────────────────────────
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {

                        // Hero
                        VStack(spacing: 8) {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.white)
                                .padding(16)
                                .background(.white.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 18))

                            Text("Buat Akun Baru")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.white)

                            Text("Bergabung dengan komunitas marketing")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.top, 56)
                        .padding(.bottom, 36)

                        // Card
                        VStack(spacing: AppTheme.Spacing.lg) {

                            // Onboarding info banner
                            HStack(spacing: 10) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(AppTheme.primary)
                                    .font(.system(size: 16))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Periode Onboarding 7 Hari")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(AppTheme.textPrimary)
                                    Text("Konsultasi admin & gabung komunitas hanya tersedia 7 hari pertama setelah daftar.")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                            }
                            .padding(12)
                            .background(AppTheme.primary.opacity(0.08))
                            .cornerRadius(AppTheme.Radius.sm)

                            // Fields
                            VStack(spacing: AppTheme.Spacing.md) {
                                fieldView(
                                    label: "Nama Lengkap",
                                    icon: "person.fill",
                                    placeholder: "Masukkan nama lengkap",
                                    text: $viewModel.fullName
                                )

                                fieldView(
                                    label: "Email",
                                    icon: "envelope.fill",
                                    placeholder: "Masukkan alamat email",
                                    text: $viewModel.email,
                                    keyboard: .emailAddress
                                )

                                secureFieldView(
                                    label: "Password",
                                    icon: "lock.fill",
                                    placeholder: "Minimal 6 karakter",
                                    text: $viewModel.password,
                                    isVisible: $showPassword
                                )

                                secureFieldView(
                                    label: "Konfirmasi Password",
                                    icon: "lock.fill",
                                    placeholder: "Ulangi password",
                                    text: $viewModel.confirmPassword,
                                    isVisible: $showConfirmPassword
                                )
                            }

                            // Error / Success
                            if let error = viewModel.errorMessage {
                                alertBanner(error, isError: true)
                            }
                            if let success = viewModel.successMessage {
                                alertBanner(success, isError: false)
                            }

                            // Register button
                            Button {
                                Task {
                                    await viewModel.register(session: session)
                                    if viewModel.successMessage != nil {
                                        try? await Task.sleep(nanoseconds: 1_500_000_000)
                                        dismiss()
                                    }
                                }
                            } label: {
                                Group {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Daftar Sekarang")
                                    }
                                }
                                .primaryButton()
                            }
                            .disabled(viewModel.isLoading)

                            // Login link
                            HStack(spacing: 4) {
                                Text("Sudah punya akun?")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.textSecondary)
                                Button("Masuk") { dismiss() }
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppTheme.primary)
                            }
                            .padding(.bottom, 8)
                        }
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .padding(.top, AppTheme.Spacing.lg)
                        .padding(.bottom, 32)
                        .background(Color(hex: "F2F2F7"))
                        .cornerRadius(28, corners: [.topLeft, .topRight])
                    }
                }
            }
            .ignoresSafeArea(.keyboard)
            .onTapGesture { hideKeyboard() }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Helpers
    private func fieldView(
        label: String,
        icon: String,
        placeholder: String,
        text: Binding<String>,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textTertiary)
                    .frame(width: 18)
                TextField(placeholder, text: text)
                    .keyboardType(keyboard)
                    .autocapitalization(keyboard == .emailAddress ? .none : .words)
                    .autocorrectionDisabled()
                    .font(.system(size: 15))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(AppTheme.surface)
            .cornerRadius(AppTheme.Radius.sm)
            .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.sm).stroke(AppTheme.divider))
        }
    }

    private func secureFieldView(
        label: String,
        icon: String,
        placeholder: String,
        text: Binding<String>,
        isVisible: Binding<Bool>
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textTertiary)
                    .frame(width: 18)
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
            .padding(.vertical, 13)
            .background(AppTheme.surface)
            .cornerRadius(AppTheme.Radius.sm)
            .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.sm).stroke(AppTheme.divider))
        }
    }

    private func alertBanner(_ message: String, isError: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: isError ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                .foregroundColor(isError ? AppTheme.error : AppTheme.success)
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(isError ? AppTheme.error : AppTheme.success)
            Spacer()
        }
        .padding(12)
        .background((isError ? AppTheme.error : AppTheme.success).opacity(0.08))
        .cornerRadius(AppTheme.Radius.sm)
    }
}

#Preview {
    RegisterView().environmentObject(SessionManager())
}
