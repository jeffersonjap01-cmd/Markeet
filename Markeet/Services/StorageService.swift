import FirebaseStorage
import Foundation
import UIKit

final class StorageService {
    static let shared = StorageService()

    private let storage = Storage.storage()

    private init() {}

    func uploadProfileImage(uid: String, image: UIImage) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.78) else {
            throw StorageServiceError.invalidImageData
        }

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        let ref = storage.reference(withPath: StoragePaths.profileImage(uid: uid))
        _ = try await ref.putDataAsync(data, metadata: metadata)
        return try await ref.downloadURL().absoluteString
    }
}

enum StorageServiceError: LocalizedError {
    case invalidImageData

    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            "The selected image could not be uploaded."
        }
    }
}
