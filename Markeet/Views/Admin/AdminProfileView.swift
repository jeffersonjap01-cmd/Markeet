import SwiftUI

/// Simplified admin profile screen.
/// Account-focused admin profile screen retained for profile/logout flows.
struct AdminProfileView: View {
    // MARK: - State

    @EnvironmentObject private var session: SessionManager
    @State private var showingLogoutAlert = false
    @State private var showingEditProfile = false
    @State private var message: String?
    @State private var errorMessage: String?
    @State private var isSendingPasswordReset = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                if let user = session.currentUser {
                    ScrollView {
                        VStack(spacing: AppTheme.Spacing.lg) {
                            profileHeader(user)
                            messageSection

                            VStack(spacing: AppTheme.Spacing.sm) {
                                Button {
                                    showingEditProfile = true
                                } label: {
                                    adminRow(icon: "square.and.pencil", title: "Edit Profile", color: AppTheme.primary)
                                }

                                Button {
                                    Task {
                                        await sendPasswordReset(to: user.email)
                                    }
                                } label: {
                                    adminRow(
                                        icon: "key.fill",
                                        title: isSendingPasswordReset ? "Sending Reset Link..." : "Change Password",
                                        color: AppTheme.info
                                    )
                                }
                                .disabled(isSendingPasswordReset)

                                Button {
                                    showingLogoutAlert = true
                                } label: {
                                    adminRow(icon: "rectangle.portrait.and.arrow.right", title: "Sign Out", color: AppTheme.error)
                                }
                            }
                            .padding(.horizontal, AppTheme.Spacing.lg)
                        }
                        .padding(.top, AppTheme.Spacing.lg)
                        .padding(.bottom, 90)
                    }
                } else {
                    EmptyStateView(
                        icon: "person.crop.circle",
                        title: "Not Signed In",
                        subtitle: "Please sign in to view your profile."
                    )
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Sign out of Markeet?", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) { session.signOut() }
            } message: {
                Text("You will need to sign in again to access your account.")
            }
            .sheet(isPresented: $showingEditProfile) {
                if let user = session.currentUser {
                    EditProfileView(user: user)
                        .environmentObject(session)
                }
            }
        }
    }

    // MARK: - Profile Sections

    private func profileHeader(_ user: UserModel) -> some View {
        VStack(spacing: AppTheme.Spacing.md) {
            ProfileAvatarView(urlString: user.profileImageURL, size: 96)
                .shadow(color: AppTheme.primary.opacity(0.16), radius: 12, y: 4)

            VStack(spacing: 6) {
                Text(user.fullName)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)

                Text(user.email)
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textSecondary)

                RoleBadge(role: user.role.displayName, color: AppTheme.roleColor(user.role))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.lg))
        .shadow(color: AppTheme.Shadow.soft, radius: 10, y: 4)
        .padding(.horizontal, AppTheme.Spacing.lg)
    }

    @ViewBuilder
    private var messageSection: some View {
        if let message {
            AdminProfileMessageCard(message: message, color: AppTheme.success, icon: "checkmark.circle.fill")
                .padding(.horizontal, AppTheme.Spacing.lg)
        }

        if let errorMessage {
            AdminProfileMessageCard(message: errorMessage, color: AppTheme.error, icon: "exclamationmark.triangle.fill")
                .padding(.horizontal, AppTheme.Spacing.lg)
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
                .foregroundColor(title == "Sign Out" ? AppTheme.error : AppTheme.textPrimary)

            Spacer()

            if title != "Sign Out" {
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

    // MARK: - Security

    private func sendPasswordReset(to email: String) async {
        isSendingPasswordReset = true
        message = nil
        errorMessage = nil
        defer { isSendingPasswordReset = false }

        do {
            try await AuthService.shared.sendPasswordReset(email: email)
            message = "A password reset link has been sent to your email."
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct AdminProfileMessageCard: View {
    let message: String
    let color: Color
    let icon: String

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(color)

            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppTheme.textPrimary)

            Spacer()
        }
        .padding(AppTheme.Spacing.md)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md))
    }
}
