import Foundation

/// Admin-created news/update document shown on Home.
/// News is stored in the `news` collection and only admins can create, edit,
/// or delete it through `NewsService`.
struct NewsModel: Identifiable, Equatable {
    let newsId: String
    var id: String { newsId }
    var title: String
    var description: String
    var imageURL: String?
    var createdAt: Date
    var createdBy: String
    var category: String
}
