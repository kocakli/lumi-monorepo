import SwiftUI

struct TermsAcceptanceView: View {
    var onAccept: () -> Void

    private let termsURL = URL(string: "https://lumi.tease.tr/terms")!
    private let privacyURL = URL(string: "https://lumi.tease.tr/privacy")!

    var body: some View {
        ZStack {
            AuroraBackground()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 24) {
                    Text("terms.title")
                        .font(LumiTheme.notoSerifDisplayLight(size: 32))
                        .foregroundStyle(LumiTheme.primary)
                        .multilineTextAlignment(.center)

                    Text("terms.body")
                        .font(.custom("PlusJakartaSans-Regular", size: 14))
                        .foregroundStyle(LumiTheme.onSurface.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 8)

                    noToleranceCard

                    linksRow
                        .padding(.top, 8)
                }
                .padding(.horizontal, 32)

                Spacer()

                agreeButton
                    .padding(.horizontal, 32)
                    .padding(.bottom, 56)
            }
        }
    }

    // MARK: - No-tolerance highlight (load-bearing for Apple/Play 1.2 UGC compliance)

    private var noToleranceCard: some View {
        Text("terms.no_tolerance")
            .font(.custom("PlusJakartaSans-Regular", size: 13))
            .fontWeight(.medium)
            .foregroundStyle(LumiTheme.onSurface)
            .multilineTextAlignment(.center)
            .lineSpacing(5)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.white.opacity(0.35))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(LumiTheme.sparklePink.opacity(0.25), lineWidth: 1)
                    )
            )
    }

    // MARK: - Terms + Privacy links

    private var linksRow: some View {
        HStack(spacing: 24) {
            Link(destination: termsURL) {
                Text("terms.terms_link")
                    .font(.custom("PlusJakartaSans-Regular", size: 12))
                    .fontWeight(.medium)
                    .underline()
                    .foregroundStyle(LumiTheme.primary)
            }

            Text("·")
                .font(.system(size: 12))
                .foregroundStyle(LumiTheme.onSurfaceVariant.opacity(0.5))

            Link(destination: privacyURL) {
                Text("terms.privacy_link")
                    .font(.custom("PlusJakartaSans-Regular", size: 12))
                    .fontWeight(.medium)
                    .underline()
                    .foregroundStyle(LumiTheme.primary)
            }
        }
    }

    // MARK: - Agree CTA

    private var agreeButton: some View {
        LumiTapTarget(accessibilityLabel: String.L("terms.agree"), action: {
            withAnimation(.easeInOut(duration: 0.3)) { onAccept() }
        }) {
            Text("terms.agree")
                .font(.custom("PlusJakartaSans-Regular", size: 14))
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .tracking(2)
                .textCase(.uppercase)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    Capsule(style: .continuous)
                        .fill(LumiTheme.sparklePink)
                        .shadow(color: LumiTheme.sparklePink.opacity(0.3), radius: 20, x: 0, y: 10)
                )
        }
    }
}
