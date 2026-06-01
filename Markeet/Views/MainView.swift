// MainView.swift
// Markeet — Main tab bar matching design screenshots
// Tabs: Beranda, Komunitas, Jadwal, Diskusi, Profil

import SwiftUI

struct MainView: View {
    @EnvironmentObject private var session: SessionManager

    var body: some View {
        TabView {
            // BERANDA (Home)
            Tab("Beranda", systemImage: "house.fill") {
                HomeView()
                    .environmentObject(session)
            }

            // KOMUNITAS (Community)
            Tab("Komunitas", systemImage: "person.3.fill") {
                ComunityView()
                    .environmentObject(session)
            }

            // JADWAL (Schedule)
            Tab("Jadwal", systemImage: "calendar") {
                ScheduleView()
                    .environmentObject(session)
            }

            // DISKUSI (Forum)
            Tab("Diskusi", systemImage: "bubble.left.and.text.bubble.right.fill") {
                FeedView()
                    .environmentObject(session)
            }

            // PROFIL (Profile)
            Tab("Profil", systemImage: "person.crop.circle.fill") {
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
