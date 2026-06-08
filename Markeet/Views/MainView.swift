// MainView.swift
// Markeet — Main tab bar matching design screenshots
// Tabs: Home, Community, Schedule, Discussion, Profile

import SwiftUI

/// Main tab structure for non-admin users.
/// Admin users are routed to `AdminMainView` before this view is shown.
struct MainView: View {
    @EnvironmentObject private var session: SessionManager

    var body: some View {
        TabView {
            // HOME
            Tab("Home", systemImage: "house.fill") {
                HomeView()
                    .environmentObject(session)
            }

            // COMMUNITY
            Tab("Community", systemImage: "person.3.fill") {
                ComunityView()
                    .environmentObject(session)
            }

            // SCHEDULE
            Tab("Schedule", systemImage: "calendar") {
                ScheduleView()
                    .environmentObject(session)
            }

            // DISCUSSION
            Tab("Discussion", systemImage: "bubble.left.and.text.bubble.right.fill") {
                FeedView()
                    .environmentObject(session)
            }

            // PROFILE
            Tab("Profile", systemImage: "person.crop.circle.fill") {
                ProfileView()
                    .environmentObject(session)
            }
        }
        .tint(AppTheme.primary)
    }
}

#Preview {
    MainView()
        .environmentObject(SessionManager())
}
