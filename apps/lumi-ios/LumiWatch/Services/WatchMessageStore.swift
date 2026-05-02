import Foundation
import SwiftUI
import WidgetKit

/// Single source of truth for the Watch app's message feed.
///
/// Storage: App Group `group.com.tease.lumi.watch`.
/// - `lumi.watch.messages.json` — JSON-encoded `[WatchMessage]` (id + text + mood)
/// - `lumi.watch.updatedAt`     — TimeInterval (latest applicationContext timestamp)
/// - `lumi.watch.favorites`     — `[String]` of message IDs the user hearted
@MainActor
final class WatchMessageStore: ObservableObject {
    static let shared = WatchMessageStore()

    @Published private(set) var messages: [WatchMessage]
    @Published private(set) var favoritedIds: Set<String>

    private static let suiteName = "group.com.tease.lumi.watch"
    private static let messagesKey = "lumi.watch.messages.json"
    private static let updatedAtKey = "lumi.watch.updatedAt"
    private static let favoritesKey = "lumi.watch.favorites"

    private var defaults: UserDefaults? {
        UserDefaults(suiteName: Self.suiteName)
    }

    private init() {
        // Hydrate messages
        if let data = UserDefaults(suiteName: Self.suiteName)?.data(forKey: Self.messagesKey),
           let cached = try? JSONDecoder().decode([WatchMessage].self, from: data),
           !cached.isEmpty {
            self.messages = cached
        } else {
            self.messages = WatchFallback.messages
        }
        // Hydrate favorites
        let savedFavs = UserDefaults(suiteName: Self.suiteName)?
            .stringArray(forKey: Self.favoritesKey) ?? []
        self.favoritedIds = Set(savedFavs)
    }

    /// Called by `WatchConnectivityService` when the iPhone pushes a new
    /// applicationContext. Empty payloads are ignored (we keep the cache).
    func update(messages: [WatchMessage], updatedAt: TimeInterval) {
        guard !messages.isEmpty else { return }

        let currentTimestamp = defaults?.double(forKey: Self.updatedAtKey) ?? 0
        if updatedAt < currentTimestamp { return }

        self.messages = messages
        if let data = try? JSONEncoder().encode(messages) {
            defaults?.set(data, forKey: Self.messagesKey)
        }
        defaults?.set(updatedAt, forKey: Self.updatedAtKey)

        // Tell the complication to refresh its timeline with the new pool.
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Favorites

    func isFavorited(_ id: String) -> Bool {
        favoritedIds.contains(id)
    }

    /// Toggle favorite locally. Returns true if the message is now
    /// favorited (i.e., should be saved to vault on iPhone).
    @discardableResult
    func toggleFavorite(_ id: String) -> Bool {
        if favoritedIds.contains(id) {
            favoritedIds.remove(id)
            persistFavorites()
            return false
        } else {
            favoritedIds.insert(id)
            persistFavorites()
            return true
        }
    }

    private func persistFavorites() {
        defaults?.set(Array(favoritedIds), forKey: Self.favoritesKey)
    }
}
