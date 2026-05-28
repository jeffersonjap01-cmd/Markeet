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

                    HStack {
                        Image(systemName: "plus")
                        Text("Post")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
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

            // SEARCH BAR
            HStack {

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 45, height: 45)
                    .overlay(
                        Text("BS")
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                    )

                Text("Apa yang ingin kamu bagikan?")
                    .foregroundColor(.gray)

                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))

            Divider()

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
    }
}

#Preview {
    FeedView()
}
