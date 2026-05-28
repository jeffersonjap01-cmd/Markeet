import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var fullName = ""
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var isLoading = false

    func login(session: SessionManager) async {
        await run {
            _ = try await AuthService.shared.login(email: self.email, password: self.password)
            await session.reloadCurrentUser()
        }
    }

    func register(session: SessionManager) async {
        await run {
            try Validators.validatePasswords(self.password, confirmation: self.confirmPassword)
            _ = try await AuthService.shared.register(fullName: self.fullName, email: self.email, password: self.password)
            await session.reloadCurrentUser()
            self.successMessage = "Account created. Please verify your email when you can."
        }
    }

    func sendPasswordReset() async {
        await run {
            try await AuthService.shared.sendPasswordReset(email: self.email)
            self.successMessage = "Password reset email sent."
        }
    }

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
