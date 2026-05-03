import SwiftUI

struct PairRequestBanner: View {
    let code: String
    let onAccept: () -> Void
    let onDecline: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "heart.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(LumiTheme.sparklePink)

                Text("pair.banner.title")
                    .font(.custom("PlusJakartaSans-Regular", size: 11))
                    .fontWeight(.semibold)
                    .foregroundStyle(LumiTheme.onSurface)
                    .kerning(1.5)

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(LumiTheme.onSurfaceVariant)
                }
            }

            Text(code.isEmpty ? String(localized: "pair.banner.someone") : code)
                .font(.custom("NotoSerif-Regular", size: 22))
                .foregroundStyle(LumiTheme.primary)
                .tracking(code.isEmpty ? 0 : 2)
            + Text(" ")
                .font(.custom("PlusJakartaSans-Regular", size: 15))
            + Text("pair.wants_to_pair")
                .font(.custom("PlusJakartaSans-Regular", size: 15))
                .foregroundStyle(LumiTheme.onSurfaceVariant)

            HStack(spacing: 12) {
                Button(action: onDecline) {
                    Text("pair.decline")
                        .font(.custom("PlusJakartaSans-Regular", size: 12))
                        .fontWeight(.medium)
                        .foregroundStyle(LumiTheme.onSurfaceVariant)
                        .kerning(1)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color.white.opacity(0.5))
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(Color.white.opacity(0.4), lineWidth: 1)
                        )
                }

                Button(action: onAccept) {
                    Text("pair.accept")
                        .font(.custom("PlusJakartaSans-Regular", size: 12))
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .kerning(1)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            Capsule(style: .continuous)
                                .fill(LumiTheme.sparklePink)
                        )
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.white.opacity(0.4))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.6), lineWidth: 1)
                )
                .shadow(color: Color(red: 0.475, green: 0.314, blue: 0.239).opacity(0.12), radius: 30, x: 0, y: 20)
        )
        .padding(.horizontal, 20)
        .padding(.top, 60)
    }
}
