import Foundation

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
