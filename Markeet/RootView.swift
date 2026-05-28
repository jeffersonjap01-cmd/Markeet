import SwiftUI

struct RootView: View {
    @StateObject private var session = SessionManager()

    var body: some View {
        Group {
            if session.isLoading {
                ProgressView("Loading Markeet")
            } else if session.currentUser == nil {
                LoginView()
                    .environmentObject(session)
            } else {
                MainTabView()
                    .environmentObject(session)
            }
        }
    }
}

#Preview {
    RootView()
}
