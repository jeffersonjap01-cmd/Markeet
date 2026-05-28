import SwiftUI

struct Comment: Identifiable {

    let id = UUID()
    var username: String
    var text: String
    var likes: Int
    var isLiked: Bool
}

struct CommentSheet: View {

    @State private var comments: [Comment] = [
        Comment(username: "Jefferson", text: "Nice post 🔥", likes: 2, isLiked: false),
        Comment(username: "Alexander", text: "Very helpful!", likes: 1, isLiked: false)
    ]

    @State private var newComment = ""

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

                VStack(spacing: 20) {

                    ForEach($comments) { $comment in

                        VStack(alignment: .leading, spacing: 10) {

                            HStack {

                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.purple, .blue],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 40, height: 40)

                                VStack(alignment: .leading) {

                                    Text(comment.username)
                                        .fontWeight(.semibold)

                                    Text(comment.text)
                                }

                                Spacer()
                            }

                            HStack(spacing: 20) {

                                Button {

                                    comment.isLiked.toggle()

                                    if comment.isLiked {
                                        comment.likes += 1
                                    } else {
                                        comment.likes -= 1
                                    }

                                } label: {

                                    Label(
                                        "\(comment.likes)",
                                        systemImage: comment.isLiked ? "heart.fill" : "heart"
                                    )
                                    .foregroundColor(
                                        comment.isLiked ? .red : .gray
                                    )
                                }

                                Button {

                                } label: {

                                    Text("Reply")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.leading, 50)
                        }
                    }
                }
                .padding()
            }

            Divider()

            HStack {

                TextField("Add comment...", text: $newComment)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(25)

                Button {

                    guard !newComment.isEmpty else { return }

                    comments.append(
                        Comment(
                            username: "You",
                            text: newComment,
                            likes: 0,
                            isLiked: false
                        )
                    )

                    newComment = ""

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
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    CommentSheet()
}
