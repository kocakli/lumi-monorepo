import SwiftUI

/// First-launch onboarding for the Watch app. Explains the two ways to
/// move between letters (swipe + Digital Crown) and dismisses on tap.
/// Shown only once per install — gated by `@AppStorage("lumi.watch.hasSeenWelcome")`.
struct WelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Spacer(minLength: 4)

                Text("Welcome to Lumi")
                    .font(WatchTheme.displayFont(size: 22))
                    .foregroundStyle(WatchTheme.ink)
                    .multilineTextAlignment(.center)

                Text("A small place for kind letters from strangers.")
                    .font(WatchTheme.bodyFont(size: 12))
                    .foregroundStyle(WatchTheme.ink.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 4)

                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "arrow.left.and.right")
                            .foregroundStyle(WatchTheme.brand)
                            .font(.system(size: 14, weight: .light))
                            .frame(width: 18)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Swipe")
                                .font(WatchTheme.bodyFont(size: 13))
                                .foregroundStyle(WatchTheme.ink)
                            Text("left or right between letters")
                                .font(WatchTheme.bodyFont(size: 11))
                                .foregroundStyle(WatchTheme.ink.opacity(0.65))
                        }
                    }
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "dial.medium")
                            .foregroundStyle(WatchTheme.brand)
                            .font(.system(size: 14, weight: .light))
                            .frame(width: 18)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Turn the crown")
                                .font(WatchTheme.bodyFont(size: 13))
                                .foregroundStyle(WatchTheme.ink)
                            Text("for a quieter, slower scroll")
                                .font(WatchTheme.bodyFont(size: 11))
                                .foregroundStyle(WatchTheme.ink.opacity(0.65))
                        }
                    }
                }
                .padding(.top, 4)
                .padding(.horizontal, 6)

                Button(action: onContinue) {
                    Text("Begin")
                        .font(WatchTheme.bodyFont(size: 14))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .tint(WatchTheme.brand)
                .padding(.top, 6)

                Spacer(minLength: 4)
            }
            .padding(.horizontal, 8)
        }
        .containerBackground(WatchTheme.backgroundGradient, for: .navigation)
    }
}

#Preview {
    WelcomeView(onContinue: {})
}
