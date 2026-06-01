// RootView.swift
// Markeet — App root: splash → auth gate → main tabs

import SwiftUI

struct RootView: View {
    @StateObject private var session = SessionManager()
    @State private var showSplash = true

    var body: some View {
        ZStack {
            Group {
                if session.isLoading {
                    Color.clear // hidden behind splash
                } else if session.currentUser == nil {
                    LoginView()
                        .environmentObject(session)
                        .transition(.opacity)
                } else {
                    MainView()
                        .environmentObject(session)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.35), value: session.currentUser != nil)

            // Splash overlay
            if showSplash {
                splashView
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                withAnimation(.easeOut(duration: 0.4)) {
                    showSplash = false
                }
            }
        }
    }

    // MARK: - Splash
    private var splashView: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 87/255, green: 79/255, blue: 222/255),
                    Color(red: 62/255, green: 55/255, blue: 180/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "chart.bar.xaxis.ascending")
                    .font(.system(size: 52, weight: .bold))
                    .foregroundColor(.white)
                    .padding(20)
                    .background(.white.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: .black.opacity(0.2), radius: 20, y: 10)

                Text("Markeet")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)

                Text("Marketing Community Platform")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
}

#Preview {
    RootView()
}
