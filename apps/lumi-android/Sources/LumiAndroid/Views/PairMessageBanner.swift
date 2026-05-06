import SwiftUI

struct PairMessageBanner: View {
    let message: InAppPairMessage
    let onView: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "envelope.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(LumiTheme.sparklePink)

                if !message.senderName.isEmpty {
                    Text(message.senderName)
                        .font(.custom("PlusJakartaSans-Regular", size: 10))
                        .fontWeight(.bold)
                        .foregroundStyle(LumiTheme.sparklePink)
                        .tracking(message.senderName.hasPrefix("LUMI-") ? 1.5 : 0.5)
                    Text("·")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(LumiTheme.onSurfaceVariant.opacity(0.5))
                }

                Text("pair_message_banner.title")
                    .font(.custom("PlusJakartaSans-Regular", size: 10))
                    .fontWeight(.semibold)
                    .foregroundStyle(LumiTheme.onSurface)
                    .tracking(1.2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Spacer()

                LumiTapTarget(accessibilityLabel: "Dismiss", action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(LumiTheme.onSurfaceVariant)
                }
            }

            Text("\u{201C}\(String(message.text.prefix(80)))\(message.text.count > 80 ? "..." : "")\u{201D}")
                .font(.custom("NotoSerif-Regular", size: 16))
                .foregroundStyle(LumiTheme.primary)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Text(message.mood.uppercased())
                    .font(.custom("PlusJakartaSans-Regular", size: 9))
                    .fontWeight(.semibold)
                    .foregroundStyle(LumiTheme.onSurfaceVariant)
                    .tracking(1.5)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.white.opacity(0.5))
                    )

                Spacer()

                LumiTapTarget(accessibilityLabel: String.L("pair_message_banner.view"), action: onView) {
                    Text("pair_message_banner.view")
                        .font(.custom("PlusJakartaSans-Regular", size: 11))
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .tracking(1)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule(style: .continuous)
                                .fill(LumiTheme.sparklePink)
                        )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.white.opacity(0.4))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(LumiTheme.sparklePink.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color(red: 0.475, green: 0.314, blue: 0.239).opacity(0.1), radius: 25, x: 0, y: 15)
        )
        .padding(.horizontal, 16)
        .padding(.top, 56)
    }
}
