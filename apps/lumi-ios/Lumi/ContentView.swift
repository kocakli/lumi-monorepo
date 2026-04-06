import SwiftUI

struct ContentView: View {
    @EnvironmentObject var router: AppRouter

    var body: some View {
        ZStack {
            AuroraBackground()

            VStack(spacing: 0) {
                // Home uses GlassNavIcon (glassmorphic circles per Figma)
                HStack {
                    Button(action: { router.navigate(to: .settings) }) {
                        GlassNavIcon(iconName: "icon-settings", width: 19, height: 19)
                    }
                    Spacer()
                    Button(action: { router.navigate(to: .vault) }) {
                        GlassNavIcon(iconName: "icon-shelves", width: 17, height: 21)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 16)

                Spacer()

                VStack(spacing: 16) {
                    Text("Lumi")
                        .font(LumiTheme.displayLarge(80))
                        .foregroundStyle(LumiTheme.onSurface.opacity(0.9))
                        .kerning(-4)
                        .frame(height: 120)
                        .transformEffect(CGAffineTransform(a: 1, b: 0, c: -0.18, d: 1, tx: 0, ty: 0))

                    Text("DIGITAL SANCTUARY")
                        .font(.custom("PlusJakartaSans-Regular", size: 10))
                        .foregroundStyle(LumiTheme.mutedText.opacity(0.6))
                        .kerning(4)
                }

                Spacer()
                    .frame(maxHeight: 32)

                VStack(spacing: 24) {
                    VStack(spacing: 24) {
                        Button(action: { router.navigate(to: .receive) }) {
                            HStack(spacing: 16) {
                                Image("icon-sparkle")
                                    .renderingMode(.template)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 20, height: 20)
                                    .foregroundStyle(LumiTheme.sparklePink)

                                Text("Receive a Message")
                                    .font(LumiTheme.bodyMedium(14))
                                    .fontWeight(.medium)
                                    .foregroundStyle(LumiTheme.buttonText)
                                    .tracking(0.4)
                            }
                            .padding(.horizontal, 41)
                            .padding(.vertical, 21)
                            .zenGlass(cornerRadius: 48, opacity: 0.4)
                        }

                        Button(action: { router.navigate(to: .write) }) {
                            HStack(spacing: 16) {
                                Image("icon-envelope")
                                    .renderingMode(.template)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 19, height: 15)
                                    .foregroundStyle(LumiTheme.mutedText)

                                Text("Say Something Nice")
                                    .font(LumiTheme.bodyMedium(14))
                                    .fontWeight(.medium)
                                    .foregroundStyle(LumiTheme.mutedText)
                                    .tracking(0.4)
                            }
                            .padding(.horizontal, 41)
                            .padding(.vertical, 21)
                            .zenGlass(cornerRadius: 48, opacity: 0.3)
                        }
                        .opacity(0.4)
                    }

                    FloatingBottomBar(
                        onAddTap: { router.navigate(to: .write) },
                        onSparkTap: { router.navigate(to: .receive) }
                    )
                    .padding(.bottom, 32)
                }
                .padding(.bottom, 16)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppRouter())
    }
}
