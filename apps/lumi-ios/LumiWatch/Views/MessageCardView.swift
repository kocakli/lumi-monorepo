import SwiftUI

/// A single positivity message rendered in the deck.
///
/// Gestures:
/// - Horizontal drag right > 60pt → like (positive rate)
/// - Horizontal drag left  > 60pt → dislike (negative rate)
/// - Heart button tap → save to vault (also toggles local "favorited" state)
///
/// Vertical drags are NOT intercepted here — they pass through to the
/// parent `TabView(.verticalPage)` for crown / vertical-swipe navigation.
struct MessageCardView: View {
    let message: WatchMessage
    let isFavorited: Bool
    let onLike: () -> Void
    let onDislike: () -> Void
    let onFavorite: () -> Void

    @State private var dragOffset: CGFloat = 0
    @State private var swipeFeedback: SwipeFeedback? = nil

    enum SwipeFeedback { case like, dislike }

    private let swipeThreshold: CGFloat = 60
    private let exitDistance: CGFloat = 240

    var body: some View {
        ZStack {
            cardContent
                .offset(x: dragOffset)
                .opacity(1.0 - min(abs(dragOffset) / 200, 0.35))

            if let feedback = swipeFeedback {
                feedbackOverlay(feedback)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(WatchTheme.backgroundGradient, for: .tabView)
        .gesture(horizontalSwipeGesture)
    }

    // MARK: - Card content

    private var cardContent: some View {
        VStack(spacing: 4) {
            Spacer(minLength: 0)

            Text("\u{201C}\(message.text)\u{201D}")
                .font(WatchTheme.displayFont(size: 22))
                .foregroundStyle(WatchTheme.ink)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .lineLimit(6)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 8)

            Spacer(minLength: 0)

            footerRow
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footerRow: some View {
        HStack {
            Button(action: onFavorite) {
                Image(systemName: isFavorited ? "heart.fill" : "heart")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(isFavorited ? WatchTheme.brand : WatchTheme.brand.opacity(0.45))
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!message.isActionable)

            Spacer()

            HStack(spacing: 4) {
                Rectangle().fill(WatchTheme.divider).frame(width: 8, height: 1)
                Text("Lumi")
                    .font(.system(size: 10, design: .serif))
                    .italic()
                    .foregroundStyle(WatchTheme.brand.opacity(0.7))
                    .kerning(1.4)
                Rectangle().fill(WatchTheme.divider).frame(width: 8, height: 1)
            }

            Spacer()

            // Symmetry spacer to keep "Lumi" optically centered.
            Color.clear.frame(width: 28, height: 28)
        }
        .padding(.horizontal, 6)
        .padding(.bottom, 4)
    }

    // MARK: - Feedback overlay

    private func feedbackOverlay(_ feedback: SwipeFeedback) -> some View {
        ZStack {
            Circle()
                .fill(feedback == .like ? Color.red.opacity(0.15) : Color.gray.opacity(0.18))
                .frame(width: 70, height: 70)
            Image(systemName: feedback == .like ? "heart.fill" : "xmark")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(feedback == .like ? Color.red.opacity(0.85) : Color.gray.opacity(0.85))
        }
    }

    // MARK: - Horizontal swipe gesture (does not intercept vertical)

    private var horizontalSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 18)
            .onChanged { value in
                // Only respond to predominantly horizontal motion. Vertical
                // drags go to TabView for paging.
                guard message.isActionable else { return }
                if abs(value.translation.width) > abs(value.translation.height) * 1.2 {
                    dragOffset = value.translation.width
                }
            }
            .onEnded { value in
                guard message.isActionable else {
                    withAnimation(.spring(response: 0.3)) { dragOffset = 0 }
                    return
                }
                let dx = value.translation.width
                let dy = value.translation.height
                let isMostlyHorizontal = abs(dx) > abs(dy) * 1.2

                if isMostlyHorizontal && dx > swipeThreshold {
                    triggerSwipe(.like, exitOffset: exitDistance, callback: onLike)
                } else if isMostlyHorizontal && dx < -swipeThreshold {
                    triggerSwipe(.dislike, exitOffset: -exitDistance, callback: onDislike)
                } else {
                    withAnimation(.spring(response: 0.3)) { dragOffset = 0 }
                }
            }
    }

    private func triggerSwipe(_ feedback: SwipeFeedback, exitOffset: CGFloat, callback: @escaping () -> Void) {
        withAnimation(.easeOut(duration: 0.22)) {
            dragOffset = exitOffset
            swipeFeedback = feedback
        }
        callback()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            withAnimation(.easeIn(duration: 0.18)) {
                swipeFeedback = nil
            }
            // Reset position without animation for the next card to enter clean
            dragOffset = 0
        }
    }
}

#Preview {
    MessageCardView(
        message: WatchMessage(id: "preview-1", text: "You are doing better than you think.", mood: "Peaceful"),
        isFavorited: false,
        onLike: {},
        onDislike: {},
        onFavorite: {}
    )
}
