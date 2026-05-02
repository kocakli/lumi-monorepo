import Foundation
import WatchConnectivity

/// Watch-side counterpart to `Lumi/Services/WatchConnectivityService.swift`.
/// Receives `applicationContext` updates pushed by the iPhone after every
/// `MessageFeedViewModel.loadFeed()` call, and forwards them to
/// `WatchMessageStore` for persistence + UI republish.
final class WatchConnectivityService: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityService()

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error {
            print("WatchConnectivity (watch): activation failed: \(error)")
            return
        }
        // On activation, the system replays the last `applicationContext`
        // received while we were suspended. Pull it now so the store can
        // hydrate from a fresh push if available.
        let received = session.receivedApplicationContext
        if !received.isEmpty {
            apply(context: received)
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        apply(context: applicationContext)
    }

    private func apply(context: [String: Any]) {
        let messages = context["messages"] as? [String] ?? []
        let updatedAt = context["updatedAt"] as? TimeInterval ?? Date().timeIntervalSince1970
        Task { @MainActor in
            WatchMessageStore.shared.update(messages: messages, updatedAt: updatedAt)
        }
    }
}
