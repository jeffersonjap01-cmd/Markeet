import Foundation

@MainActor
final class InterestOnboardingViewModel: ObservableObject {
    @Published var selectedInterests: Set<String> = []
    @Published var errorMessage: String?
    @Published var isLoading = false

    func toggleInterest(_ interest: String) {
        if selectedInterests.contains(interest) {
            selectedInterests.remove(interest)
        } else {
            selectedInterests.insert(interest)
        }
    }

    func save(session: SessionManager) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            guard let uid = session.currentUser?.uid else {
                throw InterestOnboardingError.missingUser
            }

            guard !selectedInterests.isEmpty else {
                throw InterestOnboardingError.emptySelection
            }

            let interests = AppConstants.marketingInterests.filter { selectedInterests.contains($0) }
            try await UserService.shared.updateMarketingInterests(uid: uid, interests: interests)
            await session.reloadCurrentUser()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

enum InterestOnboardingError: LocalizedError {
    case missingUser
    case emptySelection

    var errorDescription: String? {
        switch self {
        case .missingUser:
            "User session is missing."
        case .emptySelection:
            "Select at least one marketing topic."
        }
    }
}
