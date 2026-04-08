import SwiftUI
import FirebaseAuth
import FirebaseFirestore

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
            await writeUserLanguage(uid: user.uid)
            await NotificationService.shared.flushPendingToken()
            return
        }

        do {
            let result = try await Auth.auth().signInAnonymously()
            uid = result.user.uid
            isReady = true
            await writeUserLanguage(uid: result.user.uid)
            await NotificationService.shared.flushPendingToken()
        } catch {
            print("Auth error: \(error.localizedDescription)")
            // Still mark ready so app doesn't hang
            isReady = true
        }
    }

    /// Best-effort write of the user's preferred language to their Firestore doc.
    /// Backend uses this to localize FCM notifications and return messages.
    private func writeUserLanguage(uid: String) async {
        let lang = Locale.current.language.languageCode?.identifier ?? "en"
        let db = Firestore.firestore()
        try? await db.collection("users").document(uid).setData([
            "language": lang,
        ], merge: true)
    }

    /// Signs out the current Firebase user and re-creates a fresh anonymous
    /// session. Used after account deactivation — the backend has already
    /// deleted the previous auth user, so the old ID token is invalid.
    func resetToFreshAnonymousUser() async {
        // Clear published state so observers show the "not ready" gate.
        isReady = false
        uid = nil

        // Tear down the existing session. On a deleted user Firebase may
        // surface an error here; either outcome leaves us ready to re-auth.
        try? Auth.auth().signOut()

        await signInAnonymously()
    }
}
