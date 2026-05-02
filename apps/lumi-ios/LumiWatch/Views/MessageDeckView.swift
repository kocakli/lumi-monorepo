import SwiftUI

/// Horizontally paged deck of letters. `.tabViewStyle(.page)` gives the
/// native watchOS swipe-left/right gesture; Digital Crown still works as
/// a secondary scroll mechanism (system-handled on `.page` style).
///
/// First launch shows `WelcomeView` once, then this deck takes over.
struct MessageDeckView: View {
    @ObservedObject private var store = WatchMessageStore.shared
    @AppStorage("lumi.watch.hasSeenWelcome") private var hasSeenWelcome = false

    var body: some View {
        Group {
            if hasSeenWelcome {
                deck
            } else {
                WelcomeView(onContinue: { hasSeenWelcome = true })
            }
        }
    }

    private var deck: some View {
        TabView {
            ForEach(Array(store.messages.enumerated()), id: \.offset) { _, message in
                MessageCardView(message: message)
            }
        }
        .tabViewStyle(.page)
    }
}

#Preview {
    MessageDeckView()
}
