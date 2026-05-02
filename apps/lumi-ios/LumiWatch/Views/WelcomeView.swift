import SwiftUI

/// First-launch onboarding for the Watch app. Explains the gestures and
/// dismisses on tap. Shown only once per install — gated by
/// `@AppStorage("lumi.watch.hasSeenWelcome")` in MessageDeckView.
struct WelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        // Background is provided by the parent `MessageDeckView`.
        ScrollView {
                VStack(spacing: 12) {
                    Spacer(minLength: 8)

                    Text("Welcome to Lumi")
                        .font(WatchTheme.displayFont(size: 22))
                        .foregroundStyle(WatchTheme.ink)
                        .multilineTextAlignment(.center)

                    Text("Letters from strangers, found by you.")
                        .font(WatchTheme.bodyFont(size: 12))
                        .foregroundStyle(WatchTheme.ink.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 4)

                    VStack(alignment: .leading, spacing: 12) {
                        gestureRow(
                            symbol: "heart",
                            title: "Swipe right",
                            subtitle: "to send a heart and read the next letter"
                        )
                        gestureRow(
                            symbol: "xmark",
                            title: "Swipe left",
                            subtitle: "to pass quietly to the next letter"
                        )
                        gestureRow(
                            symbol: "bookmark",
                            title: "Tap the heart",
                            subtitle: "to keep this letter in your Vault"
                        )
                    }
                    .padding(.top, 6)
                    .padding(.horizontal, 6)

                    Button(action: onContinue) {
                        Text("Begin")
                            .font(WatchTheme.bodyFont(size: 14))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(WatchTheme.brand)
                    .padding(.top, 8)
                    .padding(.horizontal, 6)

                    Spacer(minLength: 4)
                }
                .padding(.horizontal, 8)
        }
    }

    private func gestureRow(symbol: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: symbol)
                .foregroundStyle(WatchTheme.brand)
                .font(.system(size: 14, weight: .light))
                .frame(width: 18, alignment: .center)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(WatchTheme.bodyFont(size: 12))
                    .foregroundStyle(WatchTheme.ink)
                Text(subtitle)
                    .font(WatchTheme.bodyFont(size: 10))
                    .foregroundStyle(WatchTheme.ink.opacity(0.6))
            }
        }
    }
}

#Preview {
    WelcomeView(onContinue: {})
}
