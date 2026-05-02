import SwiftUI

/// A single positivity message rendered in the deck.
/// Cream background, NotoSerif Light, centered, 6 line cap with auto-shrink.
struct MessageCardView: View {
    let message: String

    var body: some View {
        VStack(spacing: 8) {
            Spacer(minLength: 0)

            Text("\u{201C}\(message)\u{201D}")
                .font(WatchTheme.displayFont(size: 22))
                .foregroundStyle(WatchTheme.ink)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .lineLimit(6)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 8)

            Spacer(minLength: 0)

            // Subtle Lumi wordmark anchor
            HStack(spacing: 6) {
                Rectangle()
                    .fill(WatchTheme.divider)
                    .frame(width: 12, height: 1)
                Text("Lumi")
                    .font(.system(size: 10, design: .serif))
                    .italic()
                    .foregroundStyle(WatchTheme.brand.opacity(0.7))
                    .kerning(1.4)
                Rectangle()
                    .fill(WatchTheme.divider)
                    .frame(width: 12, height: 1)
            }
            .padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(WatchTheme.backgroundGradient, for: .tabView)
    }
}

#Preview {
    MessageCardView(message: "You are doing better than you think.")
}
