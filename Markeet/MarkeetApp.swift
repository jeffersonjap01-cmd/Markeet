import SwiftUI
import FirebaseCore

/// Application entry point.
/// Firebase is configured once before the root view starts listening for auth state.
@main
struct MarkeetApp: App {

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
