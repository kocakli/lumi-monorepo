import SwiftUI
#if os(Android)
import SkipFirebaseAuth
#else
import FirebaseAuth
#endif
#if os(Android)
import SkipFirebaseFirestore
#else
import FirebaseFirestore
#endif

/// Anonymous Firebase Auth + best-effort `users.{uid}.language` upsert.
/// Ported verbatim from apps/lumi-ios/Lumi/Services/AuthService.swift —
/// SkipFirebase mirrors the iOS API, so the Auth/Firestore calls work as-is.
///
/// Differences vs iOS:
/// - ScreenshotMode (DEBUG launch-arg switch on iOS) is not present on Android;
///   we treat the flag as always false.
/// - NotificationService.flushPendingToken() is invoked after sign-in to upsert
///   the FCM token if it arrived before auth was ready (same contract as iOS).
@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var isReady = false
    @Published var uid: String?

    private init() {
        Task { await signInAnonymously() }
    }

    private func signInAnonymously() async {
        // Already signed in?
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
            // Still mark ready so the app doesn't hang on the splash gate.
            isReady = true
        }
    }

    /// Best-effort write of the user's preferred language to their Firestore doc.
    /// Backend reads this to localize FCM notifications and (for paired flows)
    /// the recipient-side message body.
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
        isReady = false
        uid = nil
        try? Auth.auth().signOut()
        await signInAnonymously()
    }
}
