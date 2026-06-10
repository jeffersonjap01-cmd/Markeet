import Foundation

/// View model for material browsing and saved-material lists.
/// The material documents are read from Firestore, while saved state is stored
/// as material ids on the current user's profile.
@MainActor
final class MaterialsViewModel: ObservableObject {
    // MARK: - Published State

    @Published var materials: [MaterialModel] = []
    @Published var savedMaterials: [MaterialModel] = []
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var isLoading = false

    // MARK: - Loading

    func loadMaterials() async {
        await run {
            self.materials = try await MaterialService.shared.fetchMaterials()
        }
    }

    func loadSavedMaterials(for user: UserModel) async {
        await run {
            self.savedMaterials = try await MaterialService.shared.fetchMaterials(ids: user.savedMaterials)
        }
    }

    // MARK: - Save State

    func isSaved(_ material: MaterialModel, by user: UserModel?) -> Bool {
        user?.savedMaterials.contains(material.materialId) == true
    }

    func toggleSaved(material: MaterialModel, session: SessionManager) async {
        guard let user = session.currentUser else { return }

        await run {
            if user.savedMaterials.contains(material.materialId) {
                try await UserService.shared.unsaveMaterial(uid: user.uid, materialId: material.materialId)
            } else {
                try await UserService.shared.saveMaterial(uid: user.uid, materialId: material.materialId)
            }
            await session.reloadCurrentUser()
            if let refreshedUser = session.currentUser {
                self.savedMaterials = try await MaterialService.shared.fetchMaterials(ids: refreshedUser.savedMaterials)
            }
        }
    }

    // MARK: - Mentor CRUD

    func canManage(_ material: MaterialModel? = nil, session: SessionManager) -> Bool {
        guard let user = session.currentUser else { return false }
        guard user.role == .mentor || user.role == .admin else { return false }
        guard let material else { return true }
        return user.role == .admin || material.createdBy == user.uid
    }

    func saveMaterial(
        existing material: MaterialModel?,
        title: String,
        description: String,
        videoURL: String,
        thumbnailURL: String?,
        category: String?,
        tags: [String],
        session: SessionManager
    ) async {
        await run {
            guard let user = session.currentUser else {
                throw MaterialViewModelError.missingUser
            }

            if let material {
                try await MaterialService.shared.updateMaterial(
                    material,
                    title: title,
                    description: description,
                    videoURL: videoURL,
                    thumbnailURL: thumbnailURL,
                    category: category,
                    tags: tags,
                    user: user
                )
                self.successMessage = "Material updated."
            } else {
                try await MaterialService.shared.createMaterial(
                    title: title,
                    description: description,
                    videoURL: videoURL,
                    thumbnailURL: thumbnailURL,
                    category: category,
                    tags: tags,
                    mentor: user
                )
                self.successMessage = "Material added."
            }

            self.materials = try await MaterialService.shared.fetchMaterials()
        }
    }

    func deleteMaterial(_ material: MaterialModel, session: SessionManager) async {
        await run {
            guard let user = session.currentUser else {
                throw MaterialViewModelError.missingUser
            }

            try await MaterialService.shared.deleteMaterial(material, user: user)
            self.materials.removeAll { $0.materialId == material.materialId }
            self.savedMaterials.removeAll { $0.materialId == material.materialId }
            self.successMessage = "Material deleted."
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

enum MaterialViewModelError: LocalizedError {
    case missingUser

    var errorDescription: String? {
        switch self {
        case .missingUser:
            "User session is missing."
        }
    }
}
