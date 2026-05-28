import SwiftUI

struct PostCard: View {

    var initials: String
    var username: String
    var role: String
    var time: String
    var content: String
    var likes: Int
    var comments: Int

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

            HStack(spacing: 20) {

                Label("\(likes)", systemImage: "heart")
                Label("\(comments)", systemImage: "message")

                Spacer()
            }
            .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
    }
}

#Preview {
    PostCard(
        initials: "SA",
        username: "Sarah Wijaya",
        role: "Mentor",
        time: "2 jam lalu",
        content: "Tips meningkatkan engagement Instagram 📌 Posting di peak hours (11–13 & 19–21 WIB) 📌 Gunakan hashtag relevan 📌 Konsisten posting minimal 4x seminggu",
        likes: 3,
        comments: 2
    )
    .padding()
}
