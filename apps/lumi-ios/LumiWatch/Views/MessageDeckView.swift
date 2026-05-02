import SwiftUI

/// Vertically-paged deck of letters. Crown rotation and vertical swipe
/// navigate between cards. Each card additionally responds to:
/// - Horizontal swipe right → like (positive rate)
/// - Horizontal swipe left  → dislike (negative rate)
/// - Heart button tap → toggle favorite + save to Vault on iPhone
///
/// First launch shows `WelcomeView` once.
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
            ForEach(store.messages) { message in
                MessageCardView(
                    message: message,
                    isFavorited: store.isFavorited(message.id),
                    onLike: { handleRate(message, action: .ratePositive) },
                    onDislike: { handleRate(message, action: .rateNegative) },
                    onFavorite: { handleFavorite(message) }
                )
            }
        }
        .tabViewStyle(.verticalPage)
    }

    // MARK: - Actions

    private func handleRate(_ message: WatchMessage, action: WatchAction) {
        guard message.isActionable else { return }
        WatchConnectivityService.shared.sendAction(
            action,
            messageId: message.id
        )
    }

    private func handleFavorite(_ message: WatchMessage) {
        guard message.isActionable else { return }
        let nowFavorited = store.toggleFavorite(message.id)
        if nowFavorited {
            // Save to Vault on iPhone
            WatchConnectivityService.shared.sendAction(
                .save,
                messageId: message.id,
                text: message.text,
                mood: message.mood
            )
        }
        // (We don't yet support vault-removal from Watch; the local
        // un-heart is stored but no backend call is made. iPhone is the
        // source of truth for vault contents.)
    }
}

#Preview {
    MessageDeckView()
}
