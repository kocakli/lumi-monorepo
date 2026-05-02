import Foundation

/// Lightweight message model carried over WatchConnectivity. Mirrors the
/// fields from `LumiMessage` on iPhone that the Watch actually uses
/// (id + text + mood). The id is required for rate/save round-trips.
struct WatchMessage: Codable, Hashable, Identifiable {
    let id: String
    let text: String
    let mood: String

    /// Whether this message can be rated or saved to the Vault.
    /// Fallback / legacy entries lack a real backend ID and must be
    /// rendered read-only.
    var isActionable: Bool {
        !id.isEmpty
            && !id.hasPrefix("fallback-")
            && !id.hasPrefix("legacy-")
    }
}
