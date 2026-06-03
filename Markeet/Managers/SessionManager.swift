import FirebaseAuth
import Foundation

/// App-wide session object injected into SwiftUI views.
/// It bridges Firebase Auth state to the Firestore `UserModel`, which is what
/// the app uses for role-based navigation and permissions.
@MainActor
final class SessionManager: ObservableObject {
    // MARK: - Published State

    @Published var currentUser: UserModel?
    @Published var isLoading = true
    @Published var authError: String?

    private var listenerHandle: AuthStateDidChangeListenerHandle?

    // MARK: - Lifecycle

    init() {
        listenToAuthState()
    }

    deinit {
        if let listenerHandle {
            Auth.auth().removeStateDidChangeListener(listenerHandle)
        }
    }

    // MARK: - Authentication Listener

    /// Restores the app session whenever Firebase Auth signs in, signs out,
    /// or refreshes the current user.
    func listenToAuthState() {
        listenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            guard let self else { return }
            Task { @MainActor in
                await self.loadSession(firebaseUser: firebaseUser)
            }
        }
    }

    // MARK: - Session Actions

    func reloadCurrentUser() async {
        await loadSession(firebaseUser: Auth.auth().currentUser)
    }

    func signOut() {
        do {
            try AuthService.shared.signOut()
            currentUser = nil
        } catch {
            authError = error.localizedDescription
        }
    }

    // MARK: - Firestore Profile Loading

    private func loadSession(firebaseUser: FirebaseAuth.User?) async {
        isLoading = true
        defer { isLoading = false }

        guard let firebaseUser else {
            currentUser = nil
            return
        }

        do {
            let fetchedUser = try await UserService.shared.fetchUser(uid: firebaseUser.uid)
            currentUser = await OnboardingManager.shared.refreshOnboardingIfNeeded(user: fetchedUser)
        } catch {
            authError = error.localizedDescription
            currentUser = nil
        }
    }
}
