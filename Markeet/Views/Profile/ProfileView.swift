// ProfileView.swift
// Markeet — Premium profile screen matching design screenshots

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var session: SessionManager
    @State private var showingEditProfile    = false
    @State private var showingSavedMaterials = false
    @State private var showLogoutAlert       = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F2F2F7").ignoresSafeArea()

                if let user = session.currentUser {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            profileHeader(user)
                            profileContent(user)
                        }
                    }
                } else {
                    EmptyStateView(
                        icon: "person.crop.circle",
                        title: "Belum Masuk",
                        subtitle: "Silakan login untuk melihat profil kamu."
                    )
                }
            }
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingEditProfile) {
                if let user = session.currentUser {
                    EditProfileView(user: user)
                        .environmentObject(session)
                }
            }
            .sheet(isPresented: $showingSavedMaterials) {
                SavedMaterialsView()
                    .environmentObject(session)
            }
            .alert("Keluar dari Markeet?", isPresented: $showLogoutAlert) {
                Button("Batal", role: .cancel) { }
                Button("Keluar", role: .destructive) { session.signOut() }
            } message: {
                Text("Kamu harus login ulang untuk mengakses akunmu.")
            }
        }
    }

    // MARK: - Header
    @ViewBuilder
    private func profileHeader(_ user: UserModel) -> some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                ProfileAvatarView(urlString: user.profileImageURL, size: 90)
                    .shadow(color: AppTheme.primary.opacity(0.2), radius: 12, y: 4)

                // Edit badge
                Button {
                    showingEditProfile = true
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(6)
                        .background(AppTheme.primary)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                }
            }

            // Name + Role
            VStack(spacing: 6) {
                Text(user.fullName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)

                Text(user.email)
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textSecondary)

                RoleBadge(
                    role: user.role.displayName,
                    color: AppTheme.roleColor(user.role)
                )
                .padding(.top, 4)
            }

            // Bio
            if !user.bio.isEmpty {
                Text(user.bio)
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.xl)
            }

            // Stats row
            HStack(spacing: 0) {
                statItem(value: "\(user.assignedCommunities.count)", label: "Komunitas")
                Divider().frame(height: 30)
                statItem(value: "\(user.savedMaterials.count)", label: "Tersimpan")
                Divider().frame(height: 30)
                statItem(value: "\(user.registeredEvents.count)", label: "Event")
            }
            .padding(.vertical, 12)
            .background(AppTheme.surface)
            .cornerRadius(AppTheme.Radius.lg)
            .shadow(color: AppTheme.Shadow.soft, radius: 8, y: 2)
            .padding(.horizontal, AppTheme.Spacing.lg)
        }
        .padding(.top, AppTheme.Spacing.lg)
        .padding(.bottom, AppTheme.Spacing.md)
    }

    // MARK: - Content
    @ViewBuilder
    private func profileContent(_ user: UserModel) -> some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Onboarding card
            onboardingCard(user)
                .padding(.horizontal, AppTheme.Spacing.lg)

            // Menu sections
            VStack(spacing: 2) {
                menuSectionHeader("Akun")
                menuRow(icon: "pencil.line", title: "Edit Profil", color: AppTheme.primary) {
                    showingEditProfile = true
                }
                menuRow(icon: "bookmark.fill", title: "Materi Tersimpan", color: AppTheme.warning) {
                    showingSavedMaterials = true
                }
            }
            .padding(.horizontal, AppTheme.Spacing.lg)

            VStack(spacing: 2) {
                menuSectionHeader("Lainnya")
                menuRow(icon: "info.circle.fill", title: "Tentang Aplikasi", color: AppTheme.info) {
                    // Placeholder
                }
                menuRow(icon: "rectangle.portrait.and.arrow.right", title: "Keluar", color: AppTheme.error) {
                    showLogoutAlert = true
                }
            }
            .padding(.horizontal, AppTheme.Spacing.lg)

            // Version
            Text("Markeet v1.0.0")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.textTertiary)
                .padding(.top, AppTheme.Spacing.md)
                .padding(.bottom, 100)
        }
    }

    // MARK: - Onboarding Card
    @ViewBuilder
    private func onboardingCard(_ user: UserModel) -> some View {
        let isActive = user.canUseOnboardingFeatures

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: isActive ? "clock.badge.checkmark" : "clock.badge.xmark")
                    .font(.system(size: 18))
                    .foregroundColor(isActive ? AppTheme.success : AppTheme.textTertiary)

                Text("Periode Onboarding")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()

                Text(isActive ? "Aktif" : "Berakhir")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(isActive ? AppTheme.success : AppTheme.textTertiary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background((isActive ? AppTheme.success : AppTheme.textTertiary).opacity(0.12))
                    .cornerRadius(AppTheme.Radius.pill)
            }

            HStack(spacing: AppTheme.Spacing.lg) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Mulai")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textTertiary)
                    Text(user.onboardingStartDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.textPrimary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Berakhir")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textTertiary)
                    Text(user.onboardingEndDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.textPrimary)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 2) {
                    Text("Komunitas")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textTertiary)
                    Text("\(user.assignedCommunities.count)/\(AppConstants.maxJoinedCommunities)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.textPrimary)
                }
            }

            if isActive {
                // Progress bar
                let total = user.onboardingEndDate.timeIntervalSince(user.onboardingStartDate)
                let elapsed = Date().timeIntervalSince(user.onboardingStartDate)
                let progress = min(max(elapsed / total, 0), 1)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppTheme.divider)
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppTheme.primary)
                            .frame(width: geo.size.width * progress, height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.surface)
        .cornerRadius(AppTheme.Radius.lg)
        .shadow(color: AppTheme.Shadow.soft, radius: 8, y: 2)
    }

    // MARK: - Menu Components
    private func menuSectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppTheme.textTertiary)
                .textCase(.uppercase)
                .tracking(0.8)
            Spacer()
        }
        .padding(.bottom, 6)
        .padding(.top, 4)
    }

    private func menuRow(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(color)
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.1))
                    .cornerRadius(AppTheme.Radius.xs)

                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(title == "Keluar" ? AppTheme.error : AppTheme.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.textTertiary)
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, 13)
            .background(AppTheme.surface)
            .cornerRadius(AppTheme.Radius.md)
        }
    }

    // MARK: - Helpers
    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppTheme.primary)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

}

// MARK: - Profile Avatar (reusable)
struct ProfileAvatarView: View {
    let urlString: String?
    let size: CGFloat

    var body: some View {
        AsyncImage(url: urlString.flatMap(URL.init(string:))) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            default:
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(
                        AppTheme.primary.opacity(0.7),
                        AppTheme.primary.opacity(0.15)
                    )
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

#Preview {
    ProfileView().environmentObject(SessionManager())
}
