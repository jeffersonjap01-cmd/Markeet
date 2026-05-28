import FirebaseAuth
import Foundation

@MainActor
final class SessionManager: ObservableObject {
    @Published var currentUser: UserModel?
    @Published var isLoading = true
    @Published var authError: String?

    private var listenerHandle: AuthStateDidChangeListenerHandle?

    init() {
        listenToAuthState()
    }

    deinit {
        if let listenerHandle {
            Auth.auth().removeStateDidChangeListener(listenerHandle)
        }
    }

    func listenToAuthState() {
        listenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            guard let self else { return }
            Task { @MainActor in
                await self.loadSession(firebaseUser: firebaseUser)
            }
        }
    }

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
