import Foundation
import WatchConnectivity

/// Watch ↔ iPhone bridge.
///
/// Inbound (iPhone → Watch): receives `applicationContext` carrying the
/// latest message feed snapshot. Decodes rich `WatchMessage` entries
/// (id + text + mood) and forwards to `WatchMessageStore`.
///
/// Outbound (Watch → iPhone): `sendAction(_:messageId:...)` queues a
/// `transferUserInfo` so the iPhone can call the matching Cloud Function
/// (rateMessage / saveToVault). FIFO and reliable — survives reachability
/// gaps; the iPhone replays any queued userInfo packets when it next
/// activates.
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

    // MARK: - Inbound (iPhone → Watch)

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error {
            print("WatchConnectivity (watch): activation failed: \(error)")
            return
        }
        // System replays the last applicationContext on activation.
        let received = session.receivedApplicationContext
        if !received.isEmpty {
            apply(context: received)
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        apply(context: applicationContext)
    }

    private func apply(context: [String: Any]) {
        let updatedAt = context["updatedAt"] as? TimeInterval ?? Date().timeIntervalSince1970
        var messages: [WatchMessage] = []

        // New rich format: messages = [{id, text, mood}, ...]
        if let dicts = context["messages"] as? [[String: String]] {
            messages = dicts.compactMap { dict in
                guard let id = dict["id"], let text = dict["text"], let mood = dict["mood"] else { return nil }
                return WatchMessage(id: id, text: text, mood: mood)
            }
        }
        // Legacy text-only format (older iPhone builds)
        else if let texts = context["messages"] as? [String] {
            messages = texts.enumerated().map { index, text in
                WatchMessage(id: "legacy-\(index)", text: text, mood: "Peaceful")
            }
        }

        guard !messages.isEmpty else { return }

        Task { @MainActor in
            WatchMessageStore.shared.update(messages: messages, updatedAt: updatedAt)
        }
    }

    // MARK: - Outbound (Watch → iPhone)

    /// Queue an action for the iPhone to execute against the backend.
    /// Reliable delivery (transferUserInfo): survives connectivity gaps.
    func sendAction(_ action: WatchAction, messageId: String, text: String? = nil, mood: String? = nil) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { return }

        var info: [String: Any] = [
            "action": action.rawValue,
            "messageId": messageId,
        ]
        if let text { info["text"] = text }
        if let mood { info["mood"] = mood }

        session.transferUserInfo(info)
    }
}

/// Watch → iPhone action vocabulary.
enum WatchAction: String {
    case ratePositive = "rate-positive"
    case rateNegative = "rate-negative"
    case save = "save"
}
