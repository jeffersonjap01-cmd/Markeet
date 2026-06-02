import SwiftUI

struct AdminMainView: View {
    @EnvironmentObject private var session: SessionManager

    var body: some View {
        TabView {
            Tab("Home", systemImage: "house.fill") {
                AdminHomeView()
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
