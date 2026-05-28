import Foundation
import UIKit

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var user: UserModel?
    @Published var fullName = ""
    @Published var bio = ""
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var isSaving = false

    func load(uid: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let fetchedUser = try await UserService.shared.fetchUser(uid: uid)
            user = fetchedUser
            fullName = fetchedUser.fullName
            bio = fetchedUser.bio
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func prepareEditing(from user: UserModel) {
        self.user = user
        fullName = user.fullName
        bio = user.bio
    }

    func saveProfile(uid: String, selectedImage: UIImage?, session: SessionManager) async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            try Validators.validateName(fullName)
            let imageURL: String?
            if let selectedImage {
                imageURL = try await StorageService.shared.uploadProfileImage(uid: uid, image: selectedImage)
            } else {
                imageURL = nil
            }

            try await UserService.shared.updateProfile(
                uid: uid,
                fullName: fullName,
                bio: bio,
                profileImageURL: imageURL
            )
            await session.reloadCurrentUser()
            await load(uid: uid)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
