import SwiftUI

/// Simplified admin profile screen.
/// Admin-only tools are grouped here: user management, reports, settings, and logout.
struct AdminProfileView: View {
    // MARK: - State

    @EnvironmentObject private var session: SessionManager
    @State private var showingLogoutAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F2F2F7").ignoresSafeArea()

                if let user = session.currentUser {
                    ScrollView {
                        VStack(spacing: AppTheme.Spacing.md) {
                            VStack(spacing: 12) {
                                ProfileAvatarView(urlString: user.profileImageURL, size: 90)

                                VStack(spacing: 5) {
                                    Text(user.fullName)
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(AppTheme.textPrimary)

                                    Text(user.email)
                                        .font(.system(size: 13))
                                        .foregroundColor(AppTheme.textSecondary)

                                    RoleBadge(role: user.role.displayName, color: AppTheme.roleColor(user.role))
                                }
                            }
                            .padding(.top, AppTheme.Spacing.lg)

                            VStack(spacing: 2) {
                                NavigationLink {
                                    AdminUserManagementView()
                                        .environmentObject(session)
                                } label: {
                                    adminRow(icon: "person.2.badge.gearshape.fill", title: "User Management", color: AppTheme.primary)
                                }

                                NavigationLink {
                                    AdminReportsView()
                                } label: {
                                    adminRow(icon: "exclamationmark.bubble.fill", title: "Reports", color: AppTheme.warning)
                                }

                                NavigationLink {
                                    AdminSettingsView()
                                } label: {
                                    adminRow(icon: "gearshape.fill", title: "Settings", color: AppTheme.info)
                                }

                                Button {
                                    showingLogoutAlert = true
                                } label: {
                                    adminRow(icon: "rectangle.portrait.and.arrow.right", title: "Logout", color: AppTheme.error)
                                }
                            }
                            .padding(.horizontal, AppTheme.Spacing.lg)
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
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Keluar dari Markeet?", isPresented: $showingLogoutAlert) {
                Button("Batal", role: .cancel) { }
                Button("Keluar", role: .destructive) { session.signOut() }
            } message: {
                Text("Kamu harus login ulang untuk mengakses akunmu.")
            }
        }
    }

    // MARK: - Menu Row

    private func adminRow(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.1))
                .cornerRadius(AppTheme.Radius.xs)

            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(title == "Logout" ? AppTheme.error : AppTheme.textPrimary)

            Spacer()

            if title != "Logout" {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.textTertiary)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, 13)
        .background(AppTheme.surface)
        .cornerRadius(AppTheme.Radius.md)
    }
}

struct AdminSettingsView: View {
    var body: some View {
        List {
            Text("Help and support management")
            Text("Account suspension controls")
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
