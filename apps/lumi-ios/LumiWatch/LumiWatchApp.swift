import SwiftUI
import WatchKit
import UserNotifications
import WatchConnectivity

@main
struct LumiWatchApp: App {
    @WKApplicationDelegateAdaptor(LumiWatchAppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            MessageDeckView()
        }

        // Custom notification rendering for category "lumi.message".
        // Backend (sendPairRequest, sendPairMessage, sendScheduledNotifications)
        // sets `aps.category = "lumi.message"` so iPhone-mirrored pushes land
        // here on the Watch instead of the system default chrome.
        WKNotificationScene(
            controller: LumiNotificationController.self,
            category: "lumi.message"
        )
    }
}

final class LumiWatchAppDelegate: NSObject, WKApplicationDelegate {
    func applicationDidFinishLaunching() {
        // Watch does NOT register for APNs directly. iPhone-paired alert
        // pushes are mirrored automatically by iOS — we only need the user
        // to have granted notification permission so the system delivers
        // them on the Watch.
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in
            // Permission state is iPhone-controlled in practice — we ask
            // here so the Watch app's notification settings page populates
            // correctly. Result is ignored (no fallback UI).
        }

        // Activate WatchConnectivity so we receive applicationContext
        // updates from the iPhone whenever a fresh feed is fetched.
        WatchConnectivityService.shared.activate()
    }
}
