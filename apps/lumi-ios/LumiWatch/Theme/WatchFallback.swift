import Foundation

/// Curated evergreen messages shown when the Watch hasn't received any
/// real feed yet (cold launch, fresh install, or WCSession activation
/// hasn't completed). Keep tight and brand-voice on — these are literally
/// the first thing some users see on the Watch.
///
/// Mirrors `LumiWidget.SharedData.fallbackMessages` for consistency, but
/// is intentionally a separate constant so the Watch can drift slightly
/// (shorter, more breath-aware lines for a smaller canvas).
enum WatchFallback {
    static let messages: [String] = [
        "Even the smallest star shines in the darkest night.",
        "You are doing better than you think.",
        "Breathe in calm. Breathe out worry.",
        "In the quiet moments, remember: you are enough.",
        "Today, give yourself permission to rest.",
        "Your kindness is felt, even when it is quiet.",
        "Somewhere, someone is grateful you exist.",
        "The next step does not need to be big. It only needs to be yours.",
        "Be soft with yourself today.",
        "You are becoming, quietly and beautifully.",
    ]
}
