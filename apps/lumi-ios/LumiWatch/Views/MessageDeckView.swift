import SwiftUI

/// Vertical paged deck of messages, navigated by the Digital Crown.
/// `.tabViewStyle(.verticalPage)` is the watchOS-native page style — Crown
/// scrolls between pages, taps and swipes also work.
struct MessageDeckView: View {
    @ObservedObject private var store = WatchMessageStore.shared

    var body: some View {
        TabView {
            ForEach(Array(store.messages.enumerated()), id: \.offset) { _, message in
                MessageCardView(message: message)
            }
        }
        .tabViewStyle(.verticalPage)
    }
}

#Preview {
    MessageDeckView()
}
