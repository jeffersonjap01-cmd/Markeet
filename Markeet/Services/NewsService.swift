import FirebaseFirestore
import Foundation

/// Firestore service for admin-managed home news.
/// Only admins should call mutation methods; the service verifies the caller's
/// role from `users/{uid}` before creating, updating, or deleting news.
final class NewsService {
    static let shared = NewsService()

    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Admin Mutations

    func createNews(title: String, description: String, imageURL: String?, category: String, createdBy: String) async throws {
        try await assertAdmin(uid: createdBy)

        let newsId = UUID().uuidString
        let now = Date()
        let news = NewsModel(
            newsId: newsId,
            title: title,
            description: description,
            imageURL: imageURL,
            createdAt: now,
            createdBy: createdBy,
            category: category
        )

        try await newsDocument(newsId).setData(encode(news))
    }

    // MARK: - Reads

    func fetchNews() async throws -> [NewsModel] {
        let snapshot = try await db.collection(FirestoreCollections.news)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.map { document in
            decode(id: document.documentID, data: document.data())
        }
    }

    func updateNews(newsId: String, title: String, description: String, imageURL: String?, category: String, adminId: String) async throws {
        try await assertAdmin(uid: adminId)

        try await newsDocument(newsId).updateData([
            "title": title,
            "description": description,
            "imageURL": imageURL as Any,
            "category": category
        ])
    }

    func deleteNews(newsId: String, adminId: String) async throws {
        try await assertAdmin(uid: adminId)

        try await newsDocument(newsId).delete()
    }

    // MARK: - Firestore Mapping

    private func assertAdmin(uid: String) async throws {
        let user = try await UserService.shared.fetchUser(uid: uid)
        guard user.role == .admin else {
            throw NewsServiceError.adminRequired
        }
    }

    private func newsDocument(_ newsId: String) -> DocumentReference {
        db.collection(FirestoreCollections.news).document(newsId)
    }

    private func encode(_ news: NewsModel) -> [String: Any] {
        [
            "newsId": news.newsId,
            "title": news.title,
            "description": news.description,
            "imageURL": news.imageURL as Any,
            "createdAt": Timestamp(date: news.createdAt),
            "createdBy": news.createdBy,
            "category": news.category
        ]
    }

    private func decode(id: String, data: [String: Any]) -> NewsModel {
        NewsModel(
            newsId: data.string("newsId", default: id),
            title: data.string("title"),
            description: data.string("description"),
            imageURL: data["imageURL"] as? String,
            createdAt: data.date("createdAt"),
            createdBy: data.string("createdBy"),
            category: data.string("category")
        )
    }
}

enum NewsServiceError: LocalizedError {
    case adminRequired

    var errorDescription: String? {
        switch self {
        case .adminRequired:
            "Only admins can manage news."
        }
    }
}
