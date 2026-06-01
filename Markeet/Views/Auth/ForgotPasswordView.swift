// ForgotPasswordView.swift
// Markeet — Forgot password screen

import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AuthViewModel()
    @State private var didSend = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F2F2F7").ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header card
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.primary.opacity(0.12))
                                .frame(width: 80, height: 80)
                            Image(systemName: didSend ? "checkmark.circle.fill" : "lock.rotation")
                                .font(.system(size: 36))
                                .foregroundColor(AppTheme.primary)
                        }
                        .animation(.spring(response: 0.4), value: didSend)

                        Text(didSend ? "Email Terkirim!" : "Lupa Password?")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)

                        Text(didSend
                             ? "Cek email \(viewModel.email) untuk link reset password. Jangan lupa cek folder spam."
                             : "Masukkan email yang terdaftar. Kami akan mengirimkan link untuk mereset password.")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppTheme.Spacing.md)
                    }
                    .padding(.top, 60)
                    .padding(.bottom, 40)

                    // Form card
                    if !didSend {
                        VStack(spacing: AppTheme.Spacing.lg) {
                            // Email field
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Alamat Email")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(AppTheme.textSecondary)
                                HStack(spacing: 12) {
                                    Image(systemName: "envelope.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(AppTheme.textTertiary)
                                    TextField("email@contoh.com", text: $viewModel.email)
                                        .keyboardType(.emailAddress)
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

                            // Error
                            if let error = viewModel.errorMessage {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundColor(AppTheme.error)
                                    Text(error)
                                        .font(.system(size: 13))
                                        .foregroundColor(AppTheme.error)
                                    Spacer()
                                }
                                .padding(12)
                                .background(AppTheme.error.opacity(0.08))
                                .cornerRadius(AppTheme.Radius.sm)
                            }

                            // Send Button
                            Button {
                                Task {
                                    await viewModel.sendPasswordReset()
                                    if viewModel.successMessage != nil {
                                        withAnimation { didSend = true }
                                    }
                                }
                            } label: {
                                Group {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Label("Kirim Link Reset", systemImage: "paperplane.fill")
                                    }
                                }
                                .primaryButton()
                            }
                            .disabled(viewModel.isLoading || viewModel.email.isEmpty)
                        }
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    if didSend {
                        VStack(spacing: AppTheme.Spacing.md) {
                            Button {
                                dismiss()
                            } label: {
                                Text("Kembali ke Login")
                                    .primaryButton()
                            }

                            Button {
                                withAnimation { didSend = false }
                                viewModel.successMessage = nil
                                viewModel.errorMessage   = nil
                            } label: {
                                Text("Kirim ulang email")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppTheme.primary)
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.textSecondary)
                            .padding(8)
                            .background(AppTheme.divider.opacity(0.6))
                            .clipShape(Circle())
                    }
                }
            }
            .onTapGesture { hideKeyboard() }
        }
    }
}

#Preview {
    ForgotPasswordView()
}
