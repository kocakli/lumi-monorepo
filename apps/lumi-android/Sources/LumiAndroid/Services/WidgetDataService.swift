import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

/// Shared store for the rotating positivity messages displayed by the
/// home-screen widget.
///
/// - iOS: writes to an App Group `UserDefaults` and triggers a WidgetKit
///   timeline reload (matches apps/lumi-ios/Lumi/Services/WidgetDataService.swift).
/// - Android (Skip): writes to the app's default `UserDefaults`-bridge
///   (Skip maps to `SharedPreferences`); the Glance widget reads the same
///   keys and is reloaded on next refresh tick. App Groups don't exist on
///   Android — Glance widgets share the host app's process by default.
enum WidgetDataService {
    private static let suiteName = "group.com.tease.lumi"
    private static let messagesKey = "widget_messages"

    static func saveMessages(_ messages: [String]) {
        let defaults = sharedDefaults
        defaults.set(messages, forKey: messagesKey)
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #else
        // Android: Glance widgets pull on their own schedule — no manual
        // poke needed unless we want eager refresh. Faz 9 wires the
        // optional `Worker` that triggers refresh after `saveMessages`.
        #endif
    }

    static func loadMessages() -> [String] {
        sharedDefaults.stringArray(forKey: messagesKey) ?? []
    }

    private static var sharedDefaults: UserDefaults {
        #if canImport(WidgetKit)
        // iOS: prefer the App Group suite so the widget extension sees the data.
        if let groupDefaults = UserDefaults(suiteName: suiteName) {
            return groupDefaults
        }
        #endif
        // Skip path / iOS fallback: standard defaults.
        return UserDefaults.standard
    }
}
