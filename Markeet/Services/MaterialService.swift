import FirebaseFirestore
import Foundation

final class MaterialService {
    static let shared = MaterialService()

    private let db = Firestore.firestore()

    private init() {}

    func fetchMaterials(limit: Int = 30) async throws -> [MaterialModel] {
        let snapshot = try await db.collection(FirestoreCollections.materials)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.map { decode(id: $0.documentID, data: $0.data()) }
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

        return materials.sorted { $0.createdAt > $1.createdAt }
    }

    private func decode(id: String, data: [String: Any]) -> MaterialModel {
        MaterialModel(
            materialId: data.string("materialId", default: id),
            title: data.string("title"),
            description: data.string("description"),
            thumbnailURL: data["thumbnailURL"] as? String,
            contentURL: data.string("contentURL"),
            createdAt: data.date("createdAt"),
            createdBy: data.string("createdBy"),
            tags: data.stringArray("tags")
        )
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
