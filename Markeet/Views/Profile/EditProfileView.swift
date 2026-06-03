// EditProfileView.swift
// Markeet — Premium edit profile screen

import PhotosUI
import SwiftUI
import UIKit

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: SessionManager
    @StateObject private var viewModel = ProfileViewModel()

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showSuccessToast = false

    let user: UserModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F2F2F7").ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppTheme.Spacing.lg) {

                        // ── Avatar Section ───────────────────
                        VStack(spacing: 14) {
                            ZStack(alignment: .bottomTrailing) {
                                // Avatar image
                                if let selectedImage {
                                    Image(uiImage: selectedImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                        .shadow(color: AppTheme.primary.opacity(0.18), radius: 10, y: 4)
                                } else {
                                    ProfileAvatarView(urlString: user.profileImageURL, size: 100)
                                        .shadow(color: AppTheme.primary.opacity(0.18), radius: 10, y: 4)
                                }

                                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(AppTheme.primary)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.white, lineWidth: 2.5))
                                }
                            }

                            Text("Ketuk ikon kamera untuk ganti foto")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, AppTheme.Spacing.lg)

                        // ── Form Fields ──────────────────────
                        VStack(spacing: AppTheme.Spacing.md) {
                            editField(
                                label: "Nama Lengkap",
                                icon: "person.fill",
                                placeholder: "Masukkan nama lengkap",
                                text: $viewModel.fullName
                            )

                            editField(
                                label: "Email",
                                icon: "envelope.fill",
                                placeholder: "",
                                text: .constant(user.email),
                                disabled: true
                            )

                            // Bio
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Bio")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(AppTheme.textSecondary)
                                    Spacer()
                                    Text("\(viewModel.bio.count)/200")
                                        .font(.system(size: 11))
                                        .foregroundColor(
                                            viewModel.bio.count > 200
                                                ? AppTheme.error
                                                : AppTheme.textTertiary
                                        )
                                }

                                TextEditor(text: $viewModel.bio)
                                    .frame(minHeight: 80, maxHeight: 120)
                                    .padding(10)
                                    .background(AppTheme.surface)
                                    .cornerRadius(AppTheme.Radius.sm)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                                            .stroke(AppTheme.divider)
                                    )
                                    .font(.system(size: 15))
                                    .scrollContentBackground(.hidden)
                            }

                            // Role display
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Role")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(AppTheme.textSecondary)
                                HStack(spacing: 10) {
                                    Image(systemName: "shield.checkered")
                                        .font(.system(size: 14))
                                        .foregroundColor(AppTheme.textTertiary)
                                    Text(user.role.displayName)
                                        .font(.system(size: 15))
                                        .foregroundColor(AppTheme.textSecondary)
                                    Spacer()
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(AppTheme.textTertiary)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 13)
                                .background(AppTheme.background)
                                .cornerRadius(AppTheme.Radius.sm)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                                        .stroke(AppTheme.divider)
                                )
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.lg)

                        // ── Error ────────────────────────────
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
                            .padding(.horizontal, AppTheme.Spacing.lg)
                        }

                        // ── Save Button ──────────────────────
                        Button {
                            Task {
                                await viewModel.saveProfile(
                                    uid: user.uid,
                                    selectedImage: selectedImage,
                                    session: session
                                )
                                if viewModel.errorMessage == nil {
                                    dismiss()
                                }
                            }
                        } label: {
                            Group {
                                if viewModel.isSaving {
                                    HStack(spacing: 10) {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        Text("Menyimpan...")
                                            .foregroundColor(.white)
                                    }
                                } else {
                                    Label("Simpan Perubahan", systemImage: "checkmark.circle.fill")
                                }
                            }
                            .primaryButton(isEnabled: !viewModel.isSaving)
                        }
                        .disabled(viewModel.isSaving)
                        .padding(.horizontal, AppTheme.Spacing.lg)

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Edit Profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
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
            .task {
                viewModel.prepareEditing(from: user)
            }
            .onChange(of: selectedPhoto) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        selectedImage = UIImage(data: data)
                    }
                }
            }
            .onTapGesture { hideKeyboard() }
        }
    }

    // MARK: - Field Helper
    private func editField(
        label: String,
        icon: String,
        placeholder: String,
        text: Binding<String>,
        disabled: Bool = false
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
                    .font(.system(size: 15))
                    .foregroundColor(disabled ? AppTheme.textTertiary : AppTheme.textPrimary)
                    .disabled(disabled)
                if disabled {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textTertiary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(disabled ? AppTheme.background : AppTheme.surface)
            .cornerRadius(AppTheme.Radius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                    .stroke(AppTheme.divider)
            )
        }
    }
}
