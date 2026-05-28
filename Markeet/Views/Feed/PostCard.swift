import SwiftUI

struct PostCard: View {

    var initials: String
    var username: String
    var role: String
    var time: String
    var content: String

    @State var likes: Int
    @State var comments: Int

    @State private var isLiked = false
    @State private var showComments = false

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
                        Text(initials)
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                    )

                VStack(alignment: .leading, spacing: 4) {

                    HStack {

                        Text(username)
                            .font(.headline)

                        Text(role)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.purple.opacity(0.15))
                            .foregroundColor(.purple)
                            .cornerRadius(10)

                        Spacer()

                        Image(systemName: "ellipsis")
                            .foregroundColor(.gray)
                    }

                    Text(time)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            Text(content)
                .font(.body)
                .lineSpacing(5)

            HStack(spacing: 25) {

                // LIKE BUTTON
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

                // COMMENT BUTTON
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
    }
}

#Preview {
    PostCard(
        initials: "SA",
        username: "Sarah Wijaya",
        role: "Mentor",
        time: "2 jam lalu",
        content: "Tips meningkatkan engagement Instagram 📌",
        likes: 3,
        comments: 2
    )
    .padding()
}
