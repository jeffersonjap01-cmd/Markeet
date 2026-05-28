import SwiftUI
import FirebaseCore

@main
struct MarkeetApp: App {

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
