import Foundation

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

final class OnboardingManager {
    static let shared = OnboardingManager()

    private init() {}

    func canConsultAdmin(user: UserModel, at date: Date = Date()) -> Bool {
        user.onboardingActive && date <= user.onboardingEndDate && !user.bannedStatus
    }

    func canJoinCommunity(user: UserModel, at date: Date = Date()) -> Bool {
        canConsultAdmin(user: user, at: date)
            && user.assignedCommunities.count < AppConstants.maxJoinedCommunities
            && currentBatch(at: date).isRegistrationOpen(at: date)
    }

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
