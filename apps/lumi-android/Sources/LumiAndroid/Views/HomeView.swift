import SwiftUI

/// Home screen placeholder. Mirrors the structure of
/// apps/lumi-ios/Lumi/ContentView.swift — Aurora gradient + Lumi wordmark
/// header + two CTAs (Receive / Send). Full visual fidelity (Figma-pixel-
/// exact LumiHeader, FloatingBottomBar, animated cherry-blossom motifs)
/// will land in subsequent ports as those components arrive.
struct HomeView: View {
    @EnvironmentObject var router: AppRouter

    var body: some View {
        ZStack {
            AuroraBackground()

            VStack(spacing: 32) {
                Spacer(minLength: 80)

                // Lumi wordmark
                Text("Lumi")
                    .font(.custom("NotoSerif-Regular", size: 48))
                    .foregroundStyle(LumiTheme.onSurface)

                ZenLabel(text: String(localized: "letters_in_the_wind"), size: 11)

                Spacer()

                // Receive
                Button {
                    router.navigate(to: .receive)
                } label: {
                    Text(String(localized: "receive_a_message"))
                        .font(LumiTheme.body(16))
                        .fontWeight(.medium)
                        .foregroundStyle(LumiTheme.onSurface)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 18)
                        .frame(maxWidth: .infinity)
                }
                .zenGlass(cornerRadius: LumiTheme.radiusFull, opacity: 0.45)
                .padding(.horizontal, 40)

                // Send
                Button {
                    router.navigate(to: .write)
                } label: {
                    Text(String(localized: "send_a_message"))
                        .font(LumiTheme.body(16))
                        .fontWeight(.medium)
                        .foregroundStyle(LumiTheme.onSurface)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 18)
                        .frame(maxWidth: .infinity)
                }
                .zenGlass(cornerRadius: LumiTheme.radiusFull, opacity: 0.30)
                .padding(.horizontal, 40)

                Spacer(minLength: 40)
            }
            .padding(.bottom, 48)
        }
    }
}
