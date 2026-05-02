import SwiftUI
import WatchKit
import UserNotifications

/// Bridges the watchOS notification system to our SwiftUI `NotificationView`.
/// Registered via `WKNotificationScene(controller:category:)` in
/// `LumiWatchApp` for category `"lumi.message"`.
///
/// watchOS instantiates this controller, calls `didReceive(_:)` with the
/// `UNNotification`, and then renders `body` (a SwiftUI view) inside the
/// notification chrome.
final class LumiNotificationController: WKUserNotificationHostingController<NotificationView> {
    private var resolvedTitle: String = "Lumi"
    private var resolvedMessage: String = ""

    override var body: NotificationView {
        NotificationView(title: resolvedTitle, message: resolvedMessage)
    }

    override func didReceive(_ notification: UNNotification) {
        let content = notification.request.content
        // `title` is sometimes empty if the backend only set `body`; default
        // to the brand wordmark. `content.body` is the kind, inspirational message.
        resolvedTitle = content.title.isEmpty ? "Lumi" : content.title
        resolvedMessage = content.body
    }
}
