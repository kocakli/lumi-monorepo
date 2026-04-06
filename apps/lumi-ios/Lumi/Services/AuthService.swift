import SwiftUI
import FirebaseAuth

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var isReady = false
    @Published var uid: String?

    private init() {
        Task { await signInAnonymously() }
    }

    private func signInAnonymously() async {
        // If already signed in, use existing user
        if let user = Auth.auth().currentUser {
            uid = user.uid
            isReady = true
            return
        }

        do {
            let result = try await Auth.auth().signInAnonymously()
            uid = result.user.uid
            isReady = true
        } catch {
            print("Auth error: \(error.localizedDescription)")
            // Still mark ready so app doesn't hang
            isReady = true
        }
    }
}
