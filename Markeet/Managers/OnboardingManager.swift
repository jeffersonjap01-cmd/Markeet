import Foundation

/// Calendar metadata for a quarterly community batch.
/// The current product no longer shows first-login onboarding, but batch numbers
/// are still written to newly created communities for historical grouping.
struct BatchPeriod: Equatable {
    let batchNumber: Int
    let startDate: Date
    let endDate: Date

    var registrationCloseDate: Date {
        startDate.addingDays(AppConstants.onboardingDays)
    }

    func isRegistrationOpen(at date: Date = Date()) -> Bool {
        date >= startDate && date <= registrationCloseDate
    }
}

/// Maintains legacy onboarding metadata that still exists on user documents.
/// It currently provides batch calculation and quietly deactivates expired
/// onboarding flags when a session is restored.
final class OnboardingManager {
    static let shared = OnboardingManager()

    private init() {}

    // MARK: - Batch Metadata

    func currentBatch(at date: Date = Date()) -> BatchPeriod {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)

        let batchNumber: Int
        let startMonth: Int

        switch month {
        case 1...3:
            batchNumber = 1
            startMonth = 1
        case 4...6:
            batchNumber = 2
            startMonth = 4
        case 7...9:
            batchNumber = 3
            startMonth = 7
        default:
            batchNumber = 4
            startMonth = 10
        }

        let startDate = calendar.date(from: DateComponents(year: year, month: startMonth, day: 1)) ?? date
        let endDate = calendar.date(byAdding: DateComponents(month: 3, day: -1), to: startDate) ?? date
        return BatchPeriod(batchNumber: batchNumber, startDate: startDate, endDate: endDate)
    }

    // MARK: - User Compatibility

    func refreshOnboardingIfNeeded(user: UserModel) async -> UserModel {
        guard user.onboardingActive, Date() > user.onboardingEndDate else {
            return user
        }

        do {
            try await UserService.shared.deactivateOnboarding(uid: user.uid)
            var updatedUser = user
            updatedUser.onboardingActive = false
            return updatedUser
        } catch {
            return user
        }
    }
}
