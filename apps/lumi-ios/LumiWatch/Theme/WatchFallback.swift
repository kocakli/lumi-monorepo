import Foundation

/// Curated evergreen messages shown when the Watch hasn't received any
/// real feed yet (cold launch, fresh install, or WCSession activation
/// hasn't completed).
///
/// IDs are prefixed `fallback-` so `WatchMessage.isActionable` returns
/// false — gestures and the heart button are visually disabled because
/// these aren't real backend messages and can't be rated or saved.
enum WatchFallback {
    static let messages: [WatchMessage] = [
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
    ].enumerated().map { index, text in
        WatchMessage(id: "fallback-\(index)", text: text, mood: "Peaceful")
    }
}
