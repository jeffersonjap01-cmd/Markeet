import SwiftUI

/// Dedicated tab structure for admin users.
/// Admin navigation is intentionally separate from member and mentor tabs.
struct AdminMainView: View {
    @EnvironmentObject private var session: SessionManager

    var body: some View {
        TabView {
            Tab("Home", systemImage: "house.fill") {
                AdminHomeView()
                    .environmentObject(session)
            }

            Tab("User Management", systemImage: "person.2.badge.gearshape.fill") {
                NavigationStack {
                    AdminUserManagementView()
                        .environmentObject(session)
                }
            }

            Tab("Reports", systemImage: "exclamationmark.bubble.fill") {
                AdminReportsView()
                    .environmentObject(session)
            }

            Tab("Profile", systemImage: "person.crop.circle.fill") {
                AdminProfileView()
                    .environmentObject(session)
            }
        }
        .tint(AppTheme.primary)
    }
}

#Preview {
    AdminMainView()
        .environmentObject(SessionManager())
}
