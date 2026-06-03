import Foundation

/// Read-only view model for Home news.
/// Admin editing uses `AdminNewsViewModel`; this view model only fetches news
/// for regular display.
@MainActor
final class NewsViewModel: ObservableObject {
    // MARK: - Published State

    @Published var news: [NewsModel] = []
    @Published var errorMessage: String?
    @Published var isLoading = false

    // MARK: - Loading

    func loadNews() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            news = try await NewsService.shared.fetchNews()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
