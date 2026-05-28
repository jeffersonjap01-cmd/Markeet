import SwiftUI

struct PostCard: View {

    var post: Post

    var onDelete: () -> Void

    @State private var likes: Int
    @State private var comments: Int

    @State private var isLiked = false
    @State private var showComments = false

    @State private var showMenu = false
    @State private var showReportAlert = false

    init(post: Post, onDelete: @escaping () -> Void) {

        self.post = post
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

                    isLiked.toggle()

                    if isLiked {
                        likes += 1
                    } else {
                        likes -= 1
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

                    Label("\(comments)", systemImage: "message")
                        .foregroundColor(.gray)
                }

                Spacer()
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color.white)

        .sheet(isPresented: $showComments) {

            CommentSheet()
        }

        .confirmationDialog(
            "Post Options",
            isPresented: $showMenu,
            titleVisibility: .visible
        ) {

            if post.isMine {

                Button(role: .destructive) {

                    onDelete()

                } label: {

                    Label(
                        "Delete Post",
                        systemImage: "trash.fill"
                    )
                }

            } else {

                Button(role: .destructive) {

                    showReportAlert = true

                } label: {

                    Label(
                        "Report Feed",
                        systemImage: "flag.fill"
                    )
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

    PostCard(
        post: Post(
            initials: "SA",
            username: "Sarah Wijaya",
            role: "Mentor",
            time: "2 jam lalu",
            content: "Tips meningkatkan engagement Instagram 📌",
            likes: 3,
            comments: 2,
            isMine: false
        )
    ) {

    }
    .padding()
}
