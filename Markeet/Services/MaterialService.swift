import FirebaseFirestore
import Foundation

/// Firebase service for video learning materials stored in Firestore.
/// Saved materials are represented as material ids on `UserModel.savedMaterials`.
final class MaterialService {
    static let shared = MaterialService()

    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Mentor Mutations

    func createMaterial(
        title: String,
        description: String,
        videoURL: String,
        thumbnailURL: String?,
        category: String?,
        tags: [String],
        mentor: UserModel
    ) async throws {
        try validateMentor(mentor)
        let youtubeVideoId = try validateMaterialInput(title: title, videoURL: videoURL)
        let materialId = UUID().uuidString
        let now = Date()
        let resolvedThumbnail = thumbnailURL?.isEmpty == false ? thumbnailURL : YouTubeVideoHelper.thumbnailURL(for: youtubeVideoId)
        let material = MaterialModel(
            materialId: materialId,
            title: title,
            description: description,
            thumbnailURL: resolvedThumbnail,
            contentURL: videoURL,
            videoURL: videoURL,
            youtubeVideoId: youtubeVideoId,
            createdAt: now,
            updatedAt: now,
            createdBy: mentor.uid,
            mentorName: mentor.fullName,
            category: category,
            tags: tags,
            isActive: true
        )

        try await materialDocument(materialId).setData(encode(material))
    }

    func updateMaterial(
        _ material: MaterialModel,
        title: String,
        description: String,
        videoURL: String,
        thumbnailURL: String?,
        category: String?,
        tags: [String],
        user: UserModel
    ) async throws {
        try validateMaterialOwner(material, user: user)
        let youtubeVideoId = try validateMaterialInput(title: title, videoURL: videoURL)
        let resolvedThumbnail = thumbnailURL?.isEmpty == false ? thumbnailURL : YouTubeVideoHelper.thumbnailURL(for: youtubeVideoId)

        try await materialDocument(material.materialId).updateData([
            "title": title,
            "description": description,
            "thumbnailURL": resolvedThumbnail as Any,
            "contentURL": videoURL,
            "videoURL": videoURL,
            "youtubeVideoId": youtubeVideoId,
            "category": category as Any,
            "tags": tags,
            "updatedAt": Timestamp(date: Date())
        ])
    }

    func deleteMaterial(_ material: MaterialModel, user: UserModel) async throws {
        try validateMaterialOwner(material, user: user)

        try await materialDocument(material.materialId).updateData([
            "isActive": false,
            "updatedAt": Timestamp(date: Date())
        ])
    }

    // MARK: - Material Queries

    func fetchMaterials(limit: Int = 30) async throws -> [MaterialModel] {
        let snapshot = try await db.collection(FirestoreCollections.materials)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents
            .map { decode(id: $0.documentID, data: $0.data()) }
            .filter(\.isActive)
    }

    func fetchMaterials(ids: [String]) async throws -> [MaterialModel] {
        guard !ids.isEmpty else { return [] }

        var materials: [MaterialModel] = []
        for chunk in ids.chunked(into: 10) {
            let snapshot = try await db.collection(FirestoreCollections.materials)
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()
            materials.append(contentsOf: snapshot.documents.map { decode(id: $0.documentID, data: $0.data()) })
        }

        return materials.filter(\.isActive).sorted { $0.createdAt > $1.createdAt }
    }

    // MARK: - Firestore Mapping

    private func materialDocument(_ materialId: String) -> DocumentReference {
        db.collection(FirestoreCollections.materials).document(materialId)
    }

    private func encode(_ material: MaterialModel) -> [String: Any] {
        [
            "materialId": material.materialId,
            "id": material.materialId,
            "title": material.title,
            "description": material.description,
            "thumbnailURL": material.thumbnailURL as Any,
            "contentURL": material.contentURL,
            "videoURL": material.videoURL,
            "youtubeVideoId": material.youtubeVideoId,
            "createdAt": Timestamp(date: material.createdAt),
            "updatedAt": Timestamp(date: material.updatedAt),
            "createdBy": material.createdBy,
            "mentorName": material.mentorName,
            "category": material.category as Any,
            "tags": material.tags,
            "isActive": material.isActive
        ]
    }

    private func decode(id: String, data: [String: Any]) -> MaterialModel {
        let contentURL = data.string("contentURL", default: data.string("videoURL"))
        let videoURL = data.string("videoURL", default: contentURL)
        let youtubeVideoId = data.string("youtubeVideoId", default: YouTubeVideoHelper.extractVideoId(from: videoURL) ?? "")

        return MaterialModel(
            materialId: data.string("materialId", default: id),
            title: data.string("title"),
            description: data.string("description"),
            thumbnailURL: data["thumbnailURL"] as? String,
            contentURL: contentURL,
            videoURL: videoURL,
            youtubeVideoId: youtubeVideoId,
            createdAt: data.date("createdAt"),
            updatedAt: data.date("updatedAt", default: data.date("createdAt")),
            createdBy: data.string("createdBy"),
            mentorName: data.string("mentorName", default: data.string("uploaderName", default: "Mentor")),
            category: data["category"] as? String,
            tags: data.stringArray("tags"),
            isActive: data.bool("isActive", default: true)
        )
    }

    private func validateMaterialInput(title: String, videoURL: String) throws -> String {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw MaterialServiceError.emptyTitle
        }

        guard !videoURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw MaterialServiceError.emptyVideoURL
        }

        guard let youtubeVideoId = YouTubeVideoHelper.extractVideoId(from: videoURL) else {
            throw MaterialServiceError.invalidYouTubeURL
        }

        return youtubeVideoId
    }

    private func validateMentor(_ user: UserModel) throws {
        guard user.role == .mentor || user.role == .admin else {
            throw MaterialServiceError.mentorRequired
        }
    }

    private func validateMaterialOwner(_ material: MaterialModel, user: UserModel) throws {
        guard user.role == .admin || (user.role == .mentor && material.createdBy == user.uid) else {
            throw MaterialServiceError.notMaterialOwner
        }
    }
}

enum MaterialServiceError: LocalizedError {
    case emptyTitle
    case emptyVideoURL
    case invalidYouTubeURL
    case mentorRequired
    case notMaterialOwner

    var errorDescription: String? {
        switch self {
        case .emptyTitle:
            "Title cannot be empty."
        case .emptyVideoURL:
            "Video URL cannot be empty."
        case .invalidYouTubeURL:
            "Enter a valid YouTube video URL."
        case .mentorRequired:
            "Only mentors can manage learning materials."
        case .notMaterialOwner:
            "You can only edit or delete materials you uploaded."
        }
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
