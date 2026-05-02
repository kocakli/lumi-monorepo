import Foundation
import WatchConnectivity

/// Bridges the iPhone app to the paired Apple Watch via WatchConnectivity.
///
/// We use `updateApplicationContext(_:)` instead of `transferUserInfo` or
/// `sendMessage` because:
/// - It's a single, latest-state-wins snapshot (the system coalesces rapid
///   updates, so spamming `pushMessages` from `loadFeed` is fine).
/// - It survives the Watch app being suspended — the most recent context is
///   replayed on next launch.
/// - It does NOT require the counterpart to be reachable at call time.
///
/// Mirrors the contract of `WidgetDataService` (a `[String]` of message
/// texts). The iPhone is the source of truth; the Watch is a passive cache.
final class WatchConnectivityService: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityService()

    private var session: WCSession? {
        WCSession.isSupported() ? WCSession.default : nil
    }

    private override init() {
        super.init()
    }

    /// Call once on app launch (from `AppDelegate.application(_:didFinishLaunchingWithOptions:)`).
    /// Safe to call multiple times — `WCSession.activate()` is idempotent.
    func activate() {
        guard let session else { return }
        session.delegate = self
        session.activate()
    }

    /// Push the latest message snapshot to the Watch. Called whenever the
    /// iPhone fetches a fresh feed (alongside `WidgetDataService.saveMessages`).
    /// Silently no-ops when no Watch is paired or WCSession is not supported.
    func pushMessages(_ messages: [String]) {
        guard let session else { return }
        guard session.activationState == .activated else { return }
        // `isPaired` is iOS-only on the WCSession; if there's no paired Watch,
        // applicationContext is still accepted and just stored locally — but
        // skipping early avoids the round-trip overhead.
        guard session.isPaired else { return }
        guard session.isWatchAppInstalled else { return }

        let context: [String: Any] = [
            "messages": messages,
            "updatedAt": Date().timeIntervalSince1970,
        ]
        do {
            try session.updateApplicationContext(context)
        } catch {
            // Most failures are transient; the next loadFeed will retry.
            print("WatchConnectivity: updateApplicationContext failed: \(error)")
        }
    }

    // MARK: - WCSessionDelegate (iOS-only required stubs)

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error {
            print("WatchConnectivity: activation failed: \(error)")
        }
    }

    /// iOS requires these two stubs — the Watch counterpart does not.
    /// They allow the system to switch the active paired Watch (e.g., when
    /// the user pairs a new Watch). We just re-activate.
    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
}
