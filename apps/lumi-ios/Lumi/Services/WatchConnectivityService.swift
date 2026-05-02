import Foundation
import WatchConnectivity

/// Bridges the iPhone app to the paired Apple Watch via WatchConnectivity.
///
/// Outbound (iPhone → Watch): `pushMessages(_:)` uses
/// `updateApplicationContext` (latest-state-wins, coalesced, replays on
/// activation) to send the current feed snapshot as rich `[id, text, mood]`
/// dicts.
///
/// Inbound (Watch → iPhone): the Watch queues actions via
/// `transferUserInfo` (FIFO, reliable). We dispatch them to
/// `CloudFunctionService` for the actual rate/save backend calls.
final class WatchConnectivityService: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityService()

    private var session: WCSession? {
        WCSession.isSupported() ? WCSession.default : nil
    }

    private override init() {
        super.init()
    }

    /// Call once on app launch (from `AppDelegate.application(_:didFinishLaunchingWithOptions:)`).
    func activate() {
        guard let session else { return }
        session.delegate = self
        session.activate()
    }

    // MARK: - Outbound (iPhone → Watch): feed snapshot

    /// Push the latest message snapshot to the Watch. Carries enough
    /// context (id + mood) for the Watch to round-trip rate/save actions.
    func pushMessages(_ messages: [LumiMessage]) {
        guard let session else { return }
        guard session.activationState == .activated else { return }
        guard session.isPaired, session.isWatchAppInstalled else { return }

        let dicts: [[String: String]] = messages.map { msg in
            ["id": msg.id, "text": msg.text, "mood": msg.mood]
        }
        let context: [String: Any] = [
            "messages": dicts,
            "updatedAt": Date().timeIntervalSince1970,
        ]
        do {
            try session.updateApplicationContext(context)
        } catch {
            print("WatchConnectivity: updateApplicationContext failed: \(error)")
        }
    }

    // MARK: - Inbound (Watch → iPhone): action dispatch

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        let action = userInfo["action"] as? String ?? ""
        let messageId = userInfo["messageId"] as? String ?? ""
        guard !action.isEmpty, !messageId.isEmpty else { return }

        let text = userInfo["text"] as? String
        let mood = userInfo["mood"] as? String

        Task { @MainActor in
            await dispatchAction(action: action, messageId: messageId, text: text, mood: mood)
        }
    }

    @MainActor
    private func dispatchAction(action: String, messageId: String, text: String?, mood: String?) async {
        let service = CloudFunctionService.shared
        do {
            switch action {
            case "rate-positive":
                try await service.rateMessage(messageId: messageId, rating: "positive")
            case "rate-negative":
                try await service.rateMessage(messageId: messageId, rating: "negative")
            case "save":
                guard let text, let mood else {
                    print("WatchConnectivity: save action missing text/mood")
                    return
                }
                try await service.saveToVault(messageId: messageId, text: text, mood: mood)
            default:
                print("WatchConnectivity: unknown action '\(action)'")
            }
        } catch {
            // The Watch action queue is best-effort. Don't surface errors
            // to the user — iPhone remains the canonical source of truth.
            print("WatchConnectivity: dispatch '\(action)' failed: \(error)")
        }
    }

    // MARK: - WCSessionDelegate stubs

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error {
            print("WatchConnectivity: activation failed: \(error)")
        }
    }

    /// iOS-only required stubs — the Watch counterpart does not implement them.
    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
}
