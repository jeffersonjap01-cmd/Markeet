import Foundation

/// Learning material metadata stored in Firestore.
/// The actual media/content is represented by URLs; users save material ids on
/// their user profile rather than duplicating material documents.
struct MaterialModel: Identifiable, Equatable {
    let materialId: String
    var id: String { materialId }
    var title: String
    var description: String
    var thumbnailURL: String?
    var contentURL: String
    var videoURL: String
    var youtubeVideoId: String
    var createdAt: Date
    var updatedAt: Date
    var createdBy: String
    var mentorName: String
    var category: String?
    var tags: [String]
    var isActive: Bool

    var displayVideoURL: String {
        videoURL.isEmpty ? contentURL : videoURL
    }
}
