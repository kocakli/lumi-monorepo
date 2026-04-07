import SwiftUI

struct NotificationPermissionView: View {
    @EnvironmentObject var notificationService: NotificationService
    @State private var showContent = false

    var body: some View {
        ZStack {
            // Dimmed backdrop
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            // Card
            VStack(spacing: 32) {
                // Sparkle icon
                Image("icon-sparkle")
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .foregroundStyle(LumiTheme.sparklePink)
                    .padding(.top, 8)

                // Title
                Text("notif_permission.title")
                    .font(.custom("NotoSerif-Regular", size: 24))
                    .foregroundStyle(LumiTheme.onSurface)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)

                // Description
                Text("notif_permission.description")
                    .font(.custom("PlusJakartaSans-Regular", size: 14))
                    .foregroundStyle(LumiTheme.mutedText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 8)

                // Allow button
                Button {
                    Task {
                        _ = await notificationService.requestPermission()
                        dismiss()
                    }
                } label: {
                    Text("notif_permission.allow")
                        .font(.custom("PlusJakartaSans-Regular", size: 12))
                        .fontWeight(.semibold)
                        .tracking(2)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color(red: 0.925, green: 0.286, blue: 0.600))
                        )
                }

                // Maybe later
                Button {
                    dismiss()
                } label: {
                    Text("notif_permission.later")
                        .font(.custom("PlusJakartaSans-Regular", size: 13))
                        .foregroundStyle(LumiTheme.mutedText)
                }
                .padding(.bottom, 8)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 40)
            .background(
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 36, style: .continuous)
                            .fill(Color.white.opacity(0.6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 36, style: .continuous)
                            .stroke(Color.white.opacity(0.4), lineWidth: 1)
                    )
            )
            .shadow(color: LumiTheme.ambientShadow, radius: 40, x: 0, y: 20)
            .padding(.horizontal, 32)
            .scaleEffect(showContent ? 1 : 0.9)
            .opacity(showContent ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showContent = true
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.25)) {
            showContent = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            notificationService.showPrePermission = false
        }
    }
}
