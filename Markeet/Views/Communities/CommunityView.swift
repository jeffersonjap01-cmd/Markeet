import SwiftUI

struct CommunityView: View {
    
    let chats: [ChatItem] = [
        ChatItem(
            name: "Admin Markeet",
            lastMessage: "Selamat datang di Markeet!",
            time: "09:41",
            unreadCount: 1,
            color: Color.green
        ),
        
        ChatItem(
            name: "Marketing Digital Batch 3",
            lastMessage: "Sarah: Coba lihat materi SEO yang baru upload!",
            time: "Kemarin",
            unreadCount: 3,
            color: Color(red: 0.36, green: 0.27, blue: 0.95)
        ),
        
        ChatItem(
            name: "Social Media Mastery",
            lastMessage: "Rina: Ada yang sudah coba tools Canva ini?",
            time: "Senin",
            unreadCount: 0,
            color: Color.red
        )
    ]
    
    var body: some View {
        
        NavigationView {
            
            VStack(spacing: 0) {
                
                ScrollView(showsIndicators: false) {
                    
                    VStack(alignment: .leading, spacing: 0) {
                        
                        // MARK: CHAT ADMIN
                        
                        Text("CHAT ADMIN")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 20)
                            .padding(.top, 18)
                            .padding(.bottom, 10)
                        
                        NavigationLink(destination: ChatDetailView(chatName: chats[0].name)) {
                            ChatRow(chat: chats[0])
                        }
                        
                        Rectangle()
                            .fill(Color(.systemGray6))
                            .frame(height: 10)
                            .padding(.top, 6)
                        
                        // MARK: GROUP KOMUNITAS
                        
                        Text("GRUP KOMUNITAS")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 20)
                            .padding(.top, 18)
                            .padding(.bottom, 10)
                        
                        ForEach(chats.dropFirst()) { chat in
                            NavigationLink(destination: ChatDetailView(chatName: chat.name)) {
                                ChatRow(chat: chat)
                            }
                        }
                    }
                }
            }
            .background(Color(.systemGray6))
            .navigationTitle("Komunitas")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct ChatRow: View {
    
    let chat: ChatItem
    
    var body: some View {
        
        HStack(alignment: .top, spacing: 14) {
            
            // Avatar
            
            Circle()
                .fill(chat.color)
                .frame(width: 54, height: 54)
                .overlay(
                    Text(initials(from: chat.name))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 5) {
                
                Text(chat.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                
                Text(chat.lastMessage)
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 10) {
                
                Text(chat.time)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                
                if chat.unreadCount > 0 {
                    
                    Circle()
                        .fill(Color(red: 0.36, green: 0.27, blue: 0.95))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Text("\(chat.unreadCount)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.white)
    }
    
    func initials(from name: String) -> String {
        let words = name.split(separator: " ")
        let letters = words.prefix(2).compactMap { $0.first }
        return String(letters)
    }
}

struct ChatDetailView: View {
    
    let chatName: String
    
    var body: some View {
        
        VStack {
            Spacer()
            
            Text(chatName)
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Halaman Chat")
                .foregroundColor(.gray)
            
            Spacer()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ChatItem: Identifiable {
    let id = UUID()
    let name: String
    let lastMessage: String
    let time: String
    let unreadCount: Int
    let color: Color
}

#Preview {
    CommunityView()
}
