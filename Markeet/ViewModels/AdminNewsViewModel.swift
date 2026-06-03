import Foundation

/// Admin Home view model for managing platform news.
/// Admin-only validation is enforced in `NewsService`; this object focuses on
/// UI state and refreshing the local list after mutations.
@MainActor
final class AdminNewsViewModel: ObservableObject {
    // MARK: - Published State

    @Published var news: [NewsModel] = []
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var isLoading = false

    // MARK: - News Operations

    func loadNews() async {
        await run {
            self.news = try await NewsService.shared.fetchNews()
        }
    }

    func saveNews(news: NewsModel?, title: String, description: String, category: String, imageURL: String?, session: SessionManager) async {
        await run {
            guard let adminId = session.currentUser?.uid else {
                throw AdminNewsError.missingAdmin
            }

            if let news {
                try await NewsService.shared.updateNews(
                    newsId: news.newsId,
                    title: title,
                    description: description,
                    imageURL: imageURL,
                    category: category,
                    adminId: adminId
                )
                self.successMessage = "Update saved."
            } else {
                try await NewsService.shared.createNews(
                    title: title,
                    description: description,
                    imageURL: imageURL,
                    category: category,
                    createdBy: adminId
                )
                self.successMessage = "Update created."
            }

            self.news = try await NewsService.shared.fetchNews()
        }
    }

    func deleteNews(_ news: NewsModel, session: SessionManager) async {
        await run {
            guard let adminId = session.currentUser?.uid else {
                throw AdminNewsError.missingAdmin
            }

            try await NewsService.shared.deleteNews(newsId: news.newsId, adminId: adminId)
            self.news.removeAll { $0.newsId == news.newsId }
            self.successMessage = "Update deleted."
        }
    }

    // MARK: - Shared Async Wrapper

    private func run(_ operation: @escaping () async throws -> Void) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer { isLoading = false }

        do {
            try await operation()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

enum AdminNewsError: LocalizedError {
    case missingAdmin

    var errorDescription: String? {
        switch self {
        case .missingAdmin:
            "Admin session is missing."
        }
    }
}
