import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var session: SessionManager
    @State private var showingEditProfile = false
    @State private var showingSavedMaterials = false

    var body: some View {
        NavigationStack {
            List {
                if let user = session.currentUser {
                    Section {
                        HStack(spacing: 16) {
                            ProfileAvatarView(urlString: user.profileImageURL, size: 72)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.fullName)
                                    .font(.title3.bold())
                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text(user.role.displayName)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.blue)
                            }
                        }
                        if !user.bio.isEmpty {
                            Text(user.bio)
                        }
                    }

                    Section("Onboarding") {
                        LabeledContent("Status", value: user.canUseOnboardingFeatures ? "Active" : "Expired")
                        LabeledContent("Ends", value: user.onboardingEndDate.formatted(date: .abbreviated, time: .omitted))
                        LabeledContent("Joined communities", value: "\(user.assignedCommunities.count)/\(AppConstants.maxJoinedCommunities)")
                    }

                    Section("Profile") {
                        Button {
                            showingEditProfile = true
                        } label: {
                            Label("Edit Profile", systemImage: "pencil")
                        }

                        Button {
                            showingSavedMaterials = true
                        } label: {
                            Label("Saved Materials", systemImage: "bookmark")
                        }

                        LabeledContent("Registered events", value: "\(user.registeredEvents.count)")
                    }

                    Section {
                        Button(role: .destructive) {
                            session.signOut()
                        } label: {
                            Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    }
                } else {
                    ContentUnavailableView("No Profile", systemImage: "person.crop.circle", description: Text("Please sign in to view your profile."))
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showingEditProfile) {
                if let user = session.currentUser {
                    EditProfileView(user: user)
                        .environmentObject(session)
                }
            }
            .sheet(isPresented: $showingSavedMaterials) {
                SavedMaterialsView()
                    .environmentObject(session)
            }
        }
    }
}

struct ProfileAvatarView: View {
    let urlString: String?
    let size: CGFloat

    var body: some View {
        AsyncImage(url: urlString.flatMap(URL.init(string:))) { image in
            image
                .resizable()
                .scaledToFill()
        } placeholder: {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.secondary)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

#Preview {
    ProfileView()
        .environmentObject(SessionManager())
}
