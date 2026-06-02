import SwiftUI

struct PostCard: View {

    var post: FeedPost
    var currentUserId: String
    var onDelete: () -> Void

    @State private var likes: Int
    @State private var comments: Int

    @State private var isLiked = false
    @State private var showComments = false

    @State private var showMenu = false
    @State private var showReportAlert = false

    init(
        post: FeedPost,
        currentUserId: String,
        onDelete: @escaping () -> Void
    ) {

        self.post = post
        self.currentUserId = currentUserId
        self.onDelete = onDelete

        _likes = State(initialValue: post.likes)
        _comments = State(initialValue: post.comments)
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 14) {

            HStack(alignment: .top) {

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
                        Text(post.initials)
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                    )

                VStack(alignment: .leading, spacing: 4) {

                    HStack {

                        Text(post.username)
                            .font(.headline)

                        Text(post.role)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.purple.opacity(0.15))
                            .foregroundColor(.purple)
                            .cornerRadius(10)

                        Spacer()

                        Button {
                            showMenu.toggle()
                        } label: {
                            Image(systemName: "ellipsis")
                                .foregroundColor(.gray)
                        }
                    }

                    Text(post.time)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            Text(post.content)
                .font(.body)
                .lineSpacing(5)

            HStack(spacing: 25) {

                Button {

                    Task {

                        do {

                            if isLiked {

                                try await LikeService.shared.unlikePost(
                                    postId: post.postId,
                                    userId: currentUserId
                                )

                                isLiked = false
                                likes -= 1

                            } else {

                                try await LikeService.shared.likePost(
                                    postId: post.postId,
                                    userId: currentUserId
                                )

                                isLiked = true
                                likes += 1
                            }

                        } catch {

                            print(error.localizedDescription)
                        }
                    }

                } label: {

                    Label(
                        "\(likes)",
                        systemImage: isLiked ? "heart.fill" : "heart"
                    )
                    .foregroundColor(
                        isLiked ? .red : .gray
                    )
                }

                Button {
                    showComments.toggle()
                } label: {

                    Label(
                        "\(comments)",
                        systemImage: "message"
                    )
                    .foregroundColor(.gray)
                }

                Spacer()
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color.white)

        .task {

            do {

                isLiked = try await LikeService.shared.hasLiked(
                    postId: post.postId,
                    userId: currentUserId
                )

                likes = try await LikeService.shared.fetchLikeCount(
                    postId: post.postId
                )

            } catch {

                print(error.localizedDescription)
            }
        }

        .sheet(isPresented: $showComments) {
            CommentSheet(
                postId: post.postId,
                currentUserId: currentUserId
            )
        }

        .confirmationDialog(
            "Post Options",
            isPresented: $showMenu,
            titleVisibility: .visible
        ) {

            Button(
                "Delete Post",
                role: .destructive
            ) {

                Task {

                    do {

                        try await PostService.shared.deletePost(
                            postId: post.postId
                        )

                        onDelete()

                    } catch {

                        print(error.localizedDescription)
                    }
                }
            }
        }

        .alert(
            "Report Submitted",
            isPresented: $showReportAlert
        ) {

            Button("OK") { }

        } message: {

            Text("This feed has been reported to admin.")
        }
    }
}

#Preview {
    Text("PostCard Preview")
}
