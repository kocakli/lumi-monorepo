import Foundation
import SwiftUI
import WidgetKit

/// Single source of truth for the Watch app's message feed.
///
/// Reads/writes the App Group `group.com.tease.lumi.watch` — shared between
/// the Watch app and the Watch complication so the complication's timeline
/// provider can pull from the same cache.
///
/// Lifecycle:
/// 1. `init()` — synchronously load any cached messages from UserDefaults.
///    If empty, seed from `WatchFallback.messages`. UI renders immediately.
/// 2. `WatchConnectivityService` calls `update(_:)` when iPhone pushes a
///    fresh context. We persist + republish + reload widget timelines.
@MainActor
final class WatchMessageStore: ObservableObject {
    static let shared = WatchMessageStore()

    @Published private(set) var messages: [String]

    private static let suiteName = "group.com.tease.lumi.watch"
    private static let messagesKey = "lumi.watch.messages"
    private static let updatedAtKey = "lumi.watch.updatedAt"

    private var defaults: UserDefaults? {
        UserDefaults(suiteName: Self.suiteName)
    }

    private init() {
        // Synchronously hydrate from cache, fall back to evergreen strings.
        let cached = UserDefaults(suiteName: Self.suiteName)?
            .stringArray(forKey: Self.messagesKey) ?? []
        self.messages = cached.isEmpty ? WatchFallback.messages : cached
    }

    /// Called by `WatchConnectivityService` when the iPhone pushes a new
    /// applicationContext. Empty payloads are ignored (we keep the cache).
    func update(messages: [String], updatedAt: TimeInterval) {
        guard !messages.isEmpty else { return }

        // Optional staleness guard: ignore an update older than the one
        // we already have. applicationContext should always be the latest,
        // but this protects against races on Watch app cold launch.
        let currentTimestamp = defaults?.double(forKey: Self.updatedAtKey) ?? 0
        if updatedAt < currentTimestamp { return }

        self.messages = messages
        defaults?.set(messages, forKey: Self.messagesKey)
        defaults?.set(updatedAt, forKey: Self.updatedAtKey)

        // Tell the complication to refresh its timeline with the new pool.
        WidgetCenter.shared.reloadAllTimelines()
    }
}
