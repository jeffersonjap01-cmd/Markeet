import SwiftUI

struct CommentSheet: View {

    let postId: String
    let currentUserId: String

    @State private var comments: [CommentModel] = []
    @State private var newComment = ""
    @State private var likedComments: Set<String> = []
    @State private var selectedComment: CommentModel?
    @State private var showCommentMenu = false

    var body: some View {

        VStack {

            Capsule()
                .frame(width: 40, height: 5)
                .foregroundColor(.gray.opacity(0.4))
                .padding(.top, 10)

            Text("Comments")
                .font(.headline)
                .padding(.top, 5)

            ScrollView {

                LazyVStack(spacing: 16) {

                    ForEach(comments) { comment in

                        HStack(alignment: .top, spacing: 12) {

                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.purple, .blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 40, height: 40)

                            VStack(alignment: .leading, spacing: 4) {

                                Text(comment.userName)
                                    .fontWeight(.semibold)

                                Text(comment.content)

                                HStack(spacing: 15) {

                                    Button {

                                        Task {

                                            do {

                                                if likedComments.contains(comment.commentId) {

                                                    try await CommentLikeService.shared.unlikeComment(
                                                        commentId: comment.commentId,
                                                        userId: currentUserId
                                                    )

                                                    likedComments.remove(comment.commentId)

                                                } else {

                                                    try await CommentLikeService.shared.likeComment(
                                                        commentId: comment.commentId,
                                                        userId: currentUserId
                                                    )

                                                    likedComments.insert(comment.commentId)
                                                }

                                                await loadComments()

                                            } catch {

                                                print(error.localizedDescription)
                                            }
                                        }

                                    } label: {

                                        Label(
                                            "\(comment.likeCount)",
                                            systemImage: likedComments.contains(comment.commentId)
                                            ? "heart.fill"
                                            : "heart"
                                        )
                                        .foregroundColor(
                                            likedComments.contains(comment.commentId)
                                            ? .red
                                            : .gray
                                        )
                                    }
                                }

                                Text(
                                    comment.createdAt.formatted(
                                        date: .abbreviated,
                                        time: .shortened
                                    )
                                )
                                .font(.caption)
                                .foregroundColor(.gray)
                            }

                            Spacer()

                            if comment.userId == currentUserId {

                                Button {

                                    selectedComment = comment
                                    showCommentMenu = true

                                } label: {

                                    Image(systemName: "ellipsis")
                                        .foregroundColor(.gray)
                                }
                            }                        }
                    }
                }
                .padding()
            }

            Divider()

            HStack {

                TextField(
                    "Add comment...",
                    text: $newComment
                )
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(25)

                Button {

                    guard !newComment.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty else {
                        return
                    }

                    Task {

                        do {

                            let user = try await UserService.shared.fetchUser(
                                uid: currentUserId
                            )

                            try await CommentService.shared.createComment(
                                postId: postId,
                                userId: currentUserId,
                                userName: user.fullName,
                                content: newComment
                            )

                            newComment = ""

                            await loadComments()

                        } catch {

                            print(error.localizedDescription)
                        }
                    }

                } label: {

                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Circle())
                }
            }
            .padding()
        }

        .task {
            await loadComments()
        }

        .confirmationDialog(
            "Comment Options",
            isPresented: $showCommentMenu,
            titleVisibility: .visible
        ) {

            Button(
                "Delete Comment",
                role: .destructive
            ) {

                guard let comment = selectedComment else {
                    return
                }

                Task {

                    do {

                        try await CommentService.shared.deleteComment(
                            commentId: comment.commentId,
                            postId: postId
                        )

                        await loadComments()

                    } catch {

                        print(error.localizedDescription)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    @MainActor
    private func loadComments() async {

        do {

            let fetchedComments =
                try await CommentService.shared.fetchComments(
                    postId: postId
                )

            comments = fetchedComments.filter {
                !$0.deleted
            }
            var liked: Set<String> = []

            for comment in comments {

                if let hasLiked = try? await CommentLikeService.shared.hasLiked(
                    commentId: comment.commentId,
                    userId: currentUserId
                ),
                hasLiked {

                    liked.insert(comment.commentId)
                }
            }

            likedComments = liked

        } catch {

            print(error.localizedDescription)
        }
    }
}

#Preview {

    CommentSheet(
        postId: "preview",
        currentUserId: "preview"
    )
}
