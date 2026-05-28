import Foundation

@MainActor
final class MaterialsViewModel: ObservableObject {
    @Published var materials: [MaterialModel] = []
    @Published var savedMaterials: [MaterialModel] = []
    @Published var errorMessage: String?
    @Published var isLoading = false

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

    private func run(_ operation: @escaping () async throws -> Void) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await operation()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
