import Foundation

@MainActor
final class NewsViewModel: ObservableObject {
    @Published var news: [NewsModel] = []
    @Published var errorMessage: String?
    @Published var isLoading = false

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
