import SwiftUI
import UserNotifications

/// Custom-rendered watch notification. Replaces the system default look
/// when the incoming push has `aps.category == "lumi.message"` and is
/// routed through `LumiNotificationController` (see `LumiWatchApp.swift`).
///
/// The watchOS notification system passes the resolved title/body via
/// `UNNotification`, so we don't need to parse the raw payload here.
struct NotificationView: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Soft brand wordmark instead of system "Lumi" header
            Text(title.isEmpty ? "Lumi" : title)
                .font(WatchTheme.bodyFont(size: 12))
                .foregroundStyle(WatchTheme.brand.opacity(0.85))
                .kerning(0.6)

            Text(message)
                .font(WatchTheme.displayFont(size: 18))
                .foregroundStyle(WatchTheme.ink)
                .lineSpacing(2)
                .lineLimit(8)
                .minimumScaleFactor(0.75)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(WatchTheme.backgroundGradient.ignoresSafeArea())
    }
}

#Preview {
    NotificationView(
        title: "Lumi",
        message: "Even the smallest star shines in the darkest night."
    )
}
