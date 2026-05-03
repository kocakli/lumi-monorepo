import SwiftUI
import FirebaseFirestore
#if canImport(UserNotifications)
import UserNotifications
#endif
#if canImport(UIKit)
import UIKit
#endif

/// FCM token + notification preferences sync.
///
/// Ported from apps/lumi-ios/Lumi/Services/NotificationService.swift. The
/// FCM/Firestore halves are platform-agnostic (SkipFirebase mirrors the
/// iOS API). Only `requestPermission()` differs:
///
/// - iOS: `UNUserNotificationCenter.requestAuthorization` + APNs registration.
/// - Android: runtime POST_NOTIFICATIONS permission is requested by the
///   Activity layer via Compose; this method becomes a no-op stub that
///   marks state as already-asked. The real Android permission request is
///   wired in `NotificationPermissionView` (see Faz 6) and `MainActivity`.
@MainActor
final class NotificationService: ObservableObject {
    static let shared = NotificationService()

    // Preferences (persisted)
    @AppStorage("notif_enabled") var isEnabled = false
    @AppStorage("notif_frequency") var frequency: Int = 1
    @AppStorage("notif_period_morning") var periodMorning = true
    @AppStorage("notif_period_afternoon") var periodAfternoon = false
    @AppStorage("notif_period_evening") var periodEvening = false
    @AppStorage("notif_mood_playful") var moodPlayful = true
    @AppStorage("notif_mood_peaceful") var moodPeaceful = true
    @AppStorage("notif_mood_motivating") var moodMotivating = true
    @AppStorage("notif_mood_romantic") var moodRomantic = true

    // Pre-permission tracking
    @AppStorage("notif_permission_asked") var hasAskedPermission = false
    @AppStorage("notif_permission_denied") var wasDenied = false
    @AppStorage("notif_app_open_count") var appOpenCount: Int = 0

    @Published var showPrePermission = false

    // Holds the FCM token if Auth wasn't ready when it arrived
    private var pendingFCMToken: String?

    private init() {}

    var enabledMoods: [String] {
        var moods: [String] = []
        if moodPlayful { moods.append("Playful") }
        if moodPeaceful { moods.append("Peaceful") }
        if moodMotivating { moods.append("Motivating") }
        if moodRomantic { moods.append("Romantic") }
        return moods.isEmpty ? ["Peaceful", "Motivating", "Playful", "Romantic"] : moods
    }

    var enabledPeriodHours: [Int] {
        var hours: [Int] = []
        if periodMorning { hours.append(8) }
        if periodAfternoon { hours.append(13) }
        if periodEvening { hours.append(20) }
        return hours.isEmpty ? [8] : hours
    }

    var periodLabel: String {
        var labels: [String] = []
        if periodMorning { labels.append("08:00") }
        if periodAfternoon { labels.append("13:00") }
        if periodEvening { labels.append("20:00") }
        return labels.isEmpty ? "08:00" : labels.joined(separator: ", ")
    }

    // MARK: - FCM Token

    func saveFCMToken(_ token: String) async {
        // Buffer the token in case Auth isn't ready yet
        pendingFCMToken = token

        guard let uid = AuthService.shared.uid else {
            return
        }
        await writeToken(token, uid: uid)
    }

    /// Called by AuthService once anonymous sign-in completes
    func flushPendingToken() async {
        guard let token = pendingFCMToken,
              let uid = AuthService.shared.uid else { return }
        await writeToken(token, uid: uid)
    }

    private func writeToken(_ token: String, uid: String) async {
        let db = Firestore.firestore()
        do {
            try await db.collection("users").document(uid).setData([
                "fcmToken": token,
                "language": currentLanguageCode,
                "notificationPrefs": prefsDict,
            ], merge: true)
            pendingFCMToken = nil
        } catch {
            print("Failed to save FCM token: \(error)")
        }
    }

    // MARK: - Sync Preferences

    func syncPreferences() async {
        guard let uid = AuthService.shared.uid else { return }
        let db = Firestore.firestore()
        try? await db.collection("users").document(uid).setData([
            "language": currentLanguageCode,
            "notificationPrefs": prefsDict,
        ], merge: true)
    }

    /// Best-effort BCP-47 language code (e.g., "en", "ja", "zh", "tr")
    private var currentLanguageCode: String {
        Locale.current.language.languageCode?.identifier ?? "en"
    }

    private var prefsDict: [String: Any] {
        [
            "enabled": isEnabled,
            "frequency": frequency,
            "periodHours": enabledPeriodHours,
            "moods": enabledMoods,
            "timezone": TimeZone.current.identifier,
            "language": currentLanguageCode,
        ]
    }

    // MARK: - Permission

    /// Requests notification permission.
    /// - iOS: UNUserNotificationCenter + APNs registration.
    /// - Android: stub — actual permission request happens via Compose
    ///   `rememberLauncherForActivityResult` in NotificationPermissionView,
    ///   which then calls `markPermissionResult(granted:)` here.
    func requestPermission() async -> Bool {
        #if canImport(UserNotifications) && canImport(UIKit)
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            if granted {
                await MainActor.run { UIApplication.shared.registerForRemoteNotifications() }
                isEnabled = true
                hasAskedPermission = true
                wasDenied = false
                await syncPreferences()
            } else {
                wasDenied = true
                hasAskedPermission = true
            }
            return granted
        } catch {
            return false
        }
        #else
        // Android branch — the Compose layer will handle the real OS prompt
        // and feed us the result via `markPermissionResult(granted:)`.
        // Returning false here is safe; the caller doesn't trust the value
        // and re-checks `isEnabled` after the user interacts with the dialog.
        return false
        #endif
    }

    /// Called from the Android Compose permission launcher to update state.
    func markPermissionResult(granted: Bool) async {
        hasAskedPermission = true
        if granted {
            isEnabled = true
            wasDenied = false
            await syncPreferences()
        } else {
            wasDenied = true
        }
    }

    // MARK: - Pre-Permission Logic

    func checkShouldShowPrePermission() {
        if isEnabled { return }

        if !hasAskedPermission {
            showPrePermission = true
            return
        }

        if wasDenied && appOpenCount > 0 && appOpenCount % 5 == 0 {
            showPrePermission = true
        }
    }

    func incrementAppOpenCount() {
        appOpenCount += 1
    }
}
