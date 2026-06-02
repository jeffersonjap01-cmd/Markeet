import SwiftUI

struct FeedView: View {

    @EnvironmentObject var session: SessionManager

    @State private var showCreatePost = false
    @State private var posts: [FeedPost] = []

    private var userInitials: String {

        guard let name = session.currentUser?.fullName else {
            return ""
        }

        return name
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
            .map(String.init)
            .joined()
    }

    var body: some View {

        VStack(spacing: 0) {

            // HEADER
            HStack {

                Text("Diskusi Global")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Spacer()

                Button {
                    showCreatePost = true
                } label: {

                    HStack(spacing: 6) {

                        Image(systemName: "plus")

                        Text("Post")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(30)
                }
            }
            .padding()

            Divider()

            // CREATE POST
            HStack(spacing: 12) {

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(userInitials)
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                    )

                Button {

                    showCreatePost = true

                } label: {

                    HStack {

                        Text("Apa yang ingin kamu bagikan?")
                            .foregroundColor(.gray)

                        Spacer()
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(Color(.systemGray6))
                    .cornerRadius(30)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            Divider()

            ScrollView {

                VStack(spacing: 0) {

                    ForEach(posts) { post in

                        PostCard(
                            post: post,
                            currentUserId: session.currentUser?.uid ?? ""
                        ) {

                            posts.removeAll {
                                $0.id == post.id
                            }
                        }

                        Divider()
                    }
                }
            }
        }

        .task {
            await loadPosts()
        }

        .sheet(isPresented: $showCreatePost) {

            CreatePostView { newContent in

                guard let user = session.currentUser else {
                    return
                }

                Task {

                    do {

                        try await PostService.shared.createPost(
                            authorId: user.uid,
                            content: newContent
                        )

                        await loadPosts()

                    } catch {

                        print(error.localizedDescription)
                    }
                }
            }
        }
    }

    // MARK: - Load Posts

    @MainActor
    private func loadPosts() async {

        do {

            let firestorePosts = try await PostService.shared.fetchPosts()

            var loadedPosts: [FeedPost] = []

            for post in firestorePosts {

                if post.deleted {
                    continue
                }

                do {

                    let author = try await UserService.shared.fetchUser(
                        uid: post.authorId
                    )

                    let initials = author.fullName
                        .split(separator: " ")
                        .prefix(2)
                        .compactMap { $0.first }
                        .map(String.init)
                        .joined()

                    loadedPosts.append(
                        FeedPost(
                            postId: post.postId,
                            authorId: post.authorId,
                            initials: initials,
                            username: author.fullName,
                            role: author.role.displayName,
                            time: post.createdAt.formatted(
                                date: .abbreviated,
                                time: .shortened
                            ),
                            content: post.content,
                            likes: post.likeCount,
                            comments: post.commentCount,
                            isMine: author.uid == session.currentUser?.uid
                        )
                    )

                } catch {

                    print(error.localizedDescription)
                }
            }

            posts = loadedPosts

        } catch {

            print(error.localizedDescription)
        }
    }
}

#Preview {
    FeedView()
}
