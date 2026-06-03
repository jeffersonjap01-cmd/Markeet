import Foundation

/// View model for login, registration, and password reset forms.
/// It validates user input, calls Firebase Auth through `AuthService`, and asks
/// `SessionManager` to reload the Firestore profile after authentication.
@MainActor
final class AuthViewModel: ObservableObject {
    // MARK: - Form State

    @Published var fullName = ""
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var isLoading = false

    // MARK: - Authentication Actions

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
