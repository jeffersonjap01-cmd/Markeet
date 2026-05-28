import SwiftUI

struct FeedView: View {

    var body: some View {

        VStack(spacing: 0) {

            // HEADER
            HStack {

                Text("Diskusi Global")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Spacer()

                Button(action: {

                }) {

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

            // CREATE POST BUBBLE
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
                        Text("BS")
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                    )

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
            .padding(.horizontal)
            .padding(.vertical, 12)

            Divider()

            // POSTS
            ScrollView {

                VStack(spacing: 0) {

                    PostCard(
                        initials: "SA",
                        username: "Sarah Wijaya",
                        role: "Mentor",
                        time: "2 jam lalu",
                        content: "Tips meningkatkan engagement Instagram 📌 Posting di peak hours (11–13 & 19–21 WIB) 📌 Gunakan hashtag relevan 📌 Konsisten posting minimal 4x seminggu",
                        likes: 3,
                        comments: 2
                    )

                    Divider()

                    PostCard(
                        initials: "AH",
                        username: "Ahmad Fauzi",
                        role: "Member",
                        time: "4 jam lalu",
                        content: "Baru selesai baca artikel soal Google SGE dan dampaknya ke SEO 2026.",
                        likes: 2,
                        comments: 1
                    )

                    Divider()

                    PostCard(
                        initials: "SI",
                        username: "Siti Rahayu",
                        role: "Member",
                        time: "6 jam lalu",
                        content: "Ada rekomendasi tools gratis untuk analisis competitor digital?",
                        likes: 2,
                        comments: 2
                    )
                }
            }
        }
        .background(Color.white)
    }
}

#Preview {
    FeedView()
}
