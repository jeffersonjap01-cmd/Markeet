import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var session: SessionManager

    var body: some View {
        TabView {
            NewsPlaceholderView()
                .tabItem {
                    Label("News", systemImage: "newspaper")
                }

            ForumPlaceholderView()
                .tabItem {
                    Label("Forum", systemImage: "bubble.left.and.bubble.right")
                }

            MaterialsListView()
                .tabItem {
                    Label("Materials", systemImage: "book")
                }

            GroupsPlaceholderView()
                .tabItem {
                    Label("Groups", systemImage: "person.3")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
        }
    }
}

private struct NewsPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView("News", systemImage: "newspaper", description: Text("Admin-managed news will appear here."))
                .navigationTitle("News")
        }
    }
}

private struct ForumPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView("Forum", systemImage: "bubble.left.and.bubble.right", description: Text("Global discussion forum module placeholder."))
                .navigationTitle("Forum")
        }
    }
}

private struct GroupsPlaceholderView: View {
    @EnvironmentObject private var session: SessionManager

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if let user = session.currentUser {
                    let batch = OnboardingManager.shared.currentBatch()
                    Label(batch.isRegistrationOpen() ? "Registration is open" : "Registration is closed", systemImage: batch.isRegistrationOpen() ? "checkmark.seal" : "lock")
                    Text("Batch \(batch.batchNumber)")
                        .font(.title2.bold())
                    Text(OnboardingManager.shared.canJoinCommunity(user: user) ? "You can still join recommended communities." : "Community joining is unavailable for your account right now.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
            .navigationTitle("Groups")
        }
    }
}
