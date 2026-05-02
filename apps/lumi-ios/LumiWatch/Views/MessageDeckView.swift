import SwiftUI

/// Single-card deck. Same flow as the iPhone receive screen:
/// - Swipe right → like (positive rate) + advance to next
/// - Swipe left  → dislike (negative rate) + advance to next
/// - Heart button → toggle favorite + save to Vault (no advance)
///
/// First launch shows `WelcomeView` once.
struct MessageDeckView: View {
    @ObservedObject private var store = WatchMessageStore.shared
    @State private var currentIndex: Int = 0
    @AppStorage("lumi.watch.hasSeenWelcome") private var hasSeenWelcome = false

    var body: some View {
        // Cream gradient floor for the whole scene. With the deck no
        // longer inside a TabView, `.containerBackground(... for: .tabView)`
        // doesn't apply — without this ZStack, watchOS renders the system
        // black background and we lose the Lumi look.
        ZStack {
            WatchTheme.backgroundGradient
                .ignoresSafeArea()

            if hasSeenWelcome {
                deck
            } else {
                WelcomeView(onContinue: { hasSeenWelcome = true })
            }
        }
    }

    private var deck: some View {
        Group {
            if let message = currentMessage {
                MessageCardView(
                    message: message,
                    isFavorited: store.isFavorited(message.id),
                    onLike: { handleSwipe(message: message, action: .ratePositive) },
                    onDislike: { handleSwipe(message: message, action: .rateNegative) },
                    onFavorite: { handleFavorite(message) }
                )
                // Force fresh view (and reset internal drag state) on advance.
                .id(currentIndex)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.95)),
                    removal: .identity
                ))
            }
        }
        .animation(.easeIn(duration: 0.18), value: currentIndex)
    }

    private var currentMessage: WatchMessage? {
        guard !store.messages.isEmpty else { return nil }
        return store.messages[currentIndex % store.messages.count]
    }

    // MARK: - Actions

    private func handleSwipe(message: WatchMessage, action: WatchAction) {
        // Send rate (best-effort; only fires for actionable / real backend msgs)
        if message.isActionable {
            WatchConnectivityService.shared.sendAction(
                action,
                messageId: message.id
            )
        }
        // Advance — wraps around so the deck never visibly ends.
        let total = store.messages.count
        guard total > 0 else { return }
        currentIndex = (currentIndex + 1) % total
    }

    private func handleFavorite(_ message: WatchMessage) {
        let nowFavorited = store.toggleFavorite(message.id)
        guard message.isActionable else {
            // Local toggle only; no backend call for fallback messages.
            return
        }
        if nowFavorited {
            WatchConnectivityService.shared.sendAction(
                .save,
                messageId: message.id,
                text: message.text,
                mood: message.mood
            )
        }
    }
}

#Preview {
    MessageDeckView()
}
