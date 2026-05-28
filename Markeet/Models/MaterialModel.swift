import Foundation

struct MaterialModel: Identifiable, Equatable {
    let materialId: String
    var id: String { materialId }
    var title: String
    var description: String
    var thumbnailURL: String?
    var contentURL: String
    var createdAt: Date
    var createdBy: String
    var tags: [String]
}
