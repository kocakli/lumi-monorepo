import SwiftUI
import Lottie

struct MessageSentView: View {
    var onDismiss: () -> Void

    @State private var showContent = false

    var body: some View {
        ZStack {
            AuroraBackground()

            // Decorative blurred circle (bottom center, overlay blend)
            Circle()
                .fill(LumiTheme.primaryContainer)
                .frame(width: 128, height: 128)
                .blur(radius: 20)
                .blendMode(.overlay)
                .opacity(0.4)
                .offset(y: 200)

            VStack(spacing: 0) {
                Spacer(minLength: 20)

                // Paper plane Lottie animation with glow
                ZStack {
                    // Glow behind the plane
                    RadialGradient(
                        colors: [
                            Color.white,
                            LumiTheme.primaryContainer,
                            LumiTheme.primaryContainer.opacity(0),
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 80
                    )
                    .frame(width: 160, height: 160)
                    .blur(radius: 30)
                    .opacity(0.3)

                    // Lottie animation
                    LottieView(animation: .named("paper-plane"))
                        .playbackMode(.playing(.toProgress(1, loopMode: .loop)))
                        .frame(width: 384, height: 384)
                }
                .rotationEffect(.degrees(-15))

                // Vertical divider line + dot
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    LumiTheme.primary.opacity(0.3),
                                    Color.clear,
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 1, height: 24)

                    Circle()
                        .fill(LumiTheme.primary.opacity(0.4))
                        .blur(radius: 0.5)
                        .frame(width: 4, height: 4)
                }
                .opacity(0.4)

                // Typography
                VStack(spacing: 20) {
                    // Heading
                    Text("Your message has\ndissolved into the\nlight")
                        .font(.custom("NotoSerif-Regular", size: 30))
                        .foregroundStyle(LumiTheme.primary)
                        .multilineTextAlignment(.center)
                        .tracking(-0.9)
                        .lineSpacing(7)
                        .fixedSize(horizontal: false, vertical: true)

                    // Subtitle
                    Text("CARRIED BY THE SILENT WINDS OF\nTHE SANCTUARY")
                        .font(.custom("PlusJakartaSans-Regular", size: 10))
                        .fontWeight(.medium)
                        .foregroundStyle(LumiTheme.onSurfaceVariant)
                        .multilineTextAlignment(.center)
                        .tracking(4)
                        .textCase(.uppercase)
                        .opacity(0.7)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 16)

                // Return to the Garden button (glass pill)
                Button(action: onDismiss) {
                    HStack(spacing: 12) {
                        Text("RETURN TO THE GARDEN")
                            .font(.custom("PlusJakartaSans-Regular", size: 12))
                            .fontWeight(.semibold)
                            .tracking(3)

                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(LumiTheme.primary)
                    .padding(.horizontal, 41)
                    .padding(.vertical, 21)
                    .background(
                        Capsule(style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Capsule(style: .continuous)
                                    .fill(Color.white.opacity(0.3))
                            )
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
                            )
                    )
                    .shadow(
                        color: Color(red: 0.475, green: 0.314, blue: 0.239).opacity(0.06),
                        radius: 30, x: 0, y: 40
                    )
                }
                .padding(.bottom, 80)
            }
        }
        .opacity(showContent ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
            }
            // Auto-dismiss after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                onDismiss()
            }
        }
    }
}
