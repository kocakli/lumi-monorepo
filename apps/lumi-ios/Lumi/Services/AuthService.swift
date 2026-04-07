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
}
