import SwiftUI

struct FeedView: View {

    @State private var showCreatePost = false

    @State private var posts: [Post] = [

        Post(
            initials: "SA",
            username: "Sarah Wijaya",
            role: "Mentor",
            time: "2 jam lalu",
            content: "Tips meningkatkan engagement Instagram 📌 Posting di peak hours (11–13 & 19–21 WIB)",
            likes: 3,
            comments: 2,
            isMine: false
        ),

        Post(
            initials: "AH",
            username: "Ahmad Fauzi",
            role: "Member",
            time: "4 jam lalu",
            content: "Baru selesai baca artikel soal Google SGE.",
            likes: 2,
            comments: 1,
            isMine: false
        )
    ]

    var body: some View {

        VStack(spacing: 0) {

            HStack {

                Text("Diskusi Global")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Spacer()

                Button(action: {

                    showCreatePost = true

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

                Button(action: {

                    showCreatePost = true

                }) {

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
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            Divider()

            ScrollView {

                VStack(spacing: 0) {

                    ForEach(posts) { post in

                        PostCard(
                            post: post
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

        .sheet(isPresented: $showCreatePost) {

            CreatePostView { newContent in

                let newPost = Post(
                    initials: "BS",
                    username: "Bintang Student",
                    role: "Member",
                    time: "Baru saja",
                    content: newContent,
                    likes: 0,
                    comments: 0,
                    isMine: true
                )

                posts.insert(newPost, at: 0)
            }
        }

        .background(Color.white)
    }
}

#Preview {
    FeedView()
}
