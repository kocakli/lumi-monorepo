import SwiftUI

struct ReceiveMessageView: View {
    @EnvironmentObject var router: AppRouter
    @AppStorage("hasSeenSwipeOnboarding") private var hasSeenOnboarding = false
    @StateObject private var viewModel = MessageFeedViewModel()

    @State private var isShowingShare = false
    @State private var showOnboarding = false

    var body: some View {
        ZStack {
            AuroraBackground()

            VStack(spacing: 0) {
                headerBar

                if SensitiveDaysService.shared.isSensitiveToday {
                    gentleModeBadge
                        .padding(.top, 8)
                }

                Spacer()
                cardContent
                Spacer()
                bottomBar
            }

            if showOnboarding {
                SwipeOnboarding(onDismiss: {
                    withAnimation { showOnboarding = false }
                    hasSeenOnboarding = true
                })
                .transition(.opacity)
            }

            // Report confirmation toast
            if viewModel.showReportConfirmation {
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 14))
                        Text("Content reported and under review")
                            .font(.custom("PlusJakartaSans-Regular", size: 13))
                    }
                    .foregroundStyle(LumiTheme.onSurface)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        Capsule(style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Capsule(style: .continuous)
                                    .fill(Color.white.opacity(0.5))
                            )
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
                            )
                    )
                    .shadow(color: LumiTheme.ambientShadow, radius: 15, x: 0, y: 10)
                    .padding(.bottom, 120)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.4), value: viewModel.showReportConfirmation)
            }
        }
        .sheet(isPresented: $isShowingShare) {
            if let msg = viewModel.currentMessage {
                ShareMessageView(message: msg.text, mood: msg.mood)
            }
        }
        .task { await viewModel.loadFeed() }
        .onAppear {
            if !hasSeenOnboarding {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation { showOnboarding = true }
                }
            }
        }
    }

    @ViewBuilder
    private var cardContent: some View {
        if viewModel.isLoading {
            ProgressView()
                .tint(LumiTheme.primary)
        } else if let msg = viewModel.currentMessage {
            SwipeCard(
                message: msg,
                isSaved: viewModel.savedMessageIds.contains(msg.id),
                onSwipeRight: { Task { await viewModel.swipeRight() } },
                onSwipeLeft: { Task { await viewModel.swipeLeft() } },
                onSave: { Task { await viewModel.saveCurrentMessage() } },
                onShare: { isShowingShare = true },
                onReport: { Task { await viewModel.reportCurrentMessage() } }
            )
        } else {
            emptyState
        }
    }

    private var headerBar: some View {
        LumiHeader(
            onLeftTap: { router.navigate(to: .settings) },
            onRightTap: { router.navigate(to: .vault) }
        )
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("No more messages")
                .font(LumiTheme.notoSerifDisplayLight(size: 24))
                .foregroundStyle(LumiTheme.primary)
            Text("Come back later for new messages")
                .font(.custom("PlusJakartaSans-Regular", size: 14))
                .foregroundStyle(LumiTheme.mutedText)
            Button("Refresh") {
                Task { await viewModel.loadFeed() }
            }
            .font(.custom("PlusJakartaSans-Regular", size: 14))
            .fontWeight(.medium)
            .foregroundStyle(LumiTheme.primary)
            .padding(.top, 8)
        }
    }

    private var gentleModeBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "heart.fill")
                .font(.system(size: 9))
            Text("GENTLE MODE")
                .font(LumiTheme.label(9))
                .kerning(1.2)
        }
        .foregroundStyle(Color(red: 0.925, green: 0.286, blue: 0.600).opacity(0.6))
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(Color(red: 0.992, green: 0.949, blue: 0.973).opacity(0.6))
        )
    }

    private var bottomBar: some View {
        FloatingBottomBar(
            onAddTap: { router.navigate(to: .write) },
            onSparkTap: { Task { await viewModel.loadFeed() } },
            sparkleActive: true
        )
        .padding(.bottom, 32)
    }
}

// MARK: - Swipe Card

struct SwipeCard: View {
    let message: LumiMessage
    let isSaved: Bool
    var onSwipeRight: () -> Void
    var onSwipeLeft: () -> Void
    var onSave: () -> Void
    var onShare: () -> Void
    var onReport: () -> Void

    @State private var offset: CGSize = .zero
    @State private var isVisible = false

    private var swipeProgress: CGFloat { offset.width / 150 }

    var body: some View {
        ZStack {
            Circle()
                .fill(LumiTheme.primaryContainer.opacity(0.2))
                .frame(width: 256, height: 256)
                .blur(radius: 40)
                .offset(x: -80, y: -80)
            Circle()
                .fill(LumiTheme.secondaryContainer.opacity(0.2))
                .frame(width: 256, height: 256)
                .blur(radius: 40)
                .offset(x: 80, y: 80)

            cardBody
                .offset(x: offset.width, y: offset.height * 0.3)
                .rotationEffect(.degrees(Double(offset.width) / 20))
                .opacity(isVisible ? 1 : 0)
                .scaleEffect(isVisible ? 1 : 0.9)
                .gesture(swipeGesture)
        }
        .padding(.horizontal, 24)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { isVisible = true }
        }
        .id(message.id)
    }

    private var cardBody: some View {
        VStack(spacing: 0) {
            moodBadge
            messageBody
            dividerLine
            actionRow
        }
        .padding(40)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 48, style: .continuous))
        .overlay(swipeOverlay)
    }

    private var swipeOverlay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 48, style: .continuous)
                .fill(Color.green.opacity(0.08 * max(0, swipeProgress)))
                .overlay(
                    swipeProgress > 0.3
                        ? Image(systemName: "heart.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.green.opacity(min(1, swipeProgress)))
                        : nil
                )
            RoundedRectangle(cornerRadius: 48, style: .continuous)
                .fill(Color.red.opacity(0.08 * max(0, -swipeProgress)))
                .overlay(
                    swipeProgress < -0.3
                        ? Image(systemName: "xmark")
                            .font(.system(size: 40, weight: .light))
                            .foregroundStyle(.red.opacity(min(1, -swipeProgress)))
                        : nil
                )
        }
        .allowsHitTesting(false)
    }

    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { gesture in offset = gesture.translation }
            .onEnded { gesture in
                if gesture.translation.width > 120 {
                    withAnimation(.easeOut(duration: 0.3)) { offset = CGSize(width: 500, height: 0) }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        offset = .zero; isVisible = false; onSwipeRight()
                    }
                } else if gesture.translation.width < -120 {
                    withAnimation(.easeOut(duration: 0.3)) { offset = CGSize(width: -500, height: 0) }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        offset = .zero; isVisible = false; onSwipeLeft()
                    }
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { offset = .zero }
                }
            }
    }

    private var cardBg: some View {
        RoundedRectangle(cornerRadius: 48, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(RoundedRectangle(cornerRadius: 48, style: .continuous).fill(Color.white.opacity(0.3)))
            .overlay(RoundedRectangle(cornerRadius: 48, style: .continuous).stroke(Color.white.opacity(0.6), lineWidth: 1))
            .shadow(color: Color(red: 0.475, green: 0.314, blue: 0.239).opacity(0.06), radius: 30, x: 0, y: 40)
    }

    private var moodBadge: some View {
        Text(message.mood.uppercased())
            .font(.custom("PlusJakartaSans-Regular", size: 10)).fontWeight(.semibold)
            .foregroundStyle(Color(red: 0.294, green: 0.271, blue: 0.286))
            .kerning(2.5)
            .padding(.horizontal, 17).padding(.vertical, 7)
            .background(Capsule(style: .continuous).fill(Color.white.opacity(0.4)))
            .overlay(Capsule(style: .continuous).stroke(Color.white.opacity(0.5), lineWidth: 1))
            .padding(.bottom, 48)
    }

    private var messageBody: some View {
        Text(message.text)
            .font(LumiTheme.notoSerifDisplayLight(size: 26))
            .foregroundStyle(LumiTheme.primary)
            .multilineTextAlignment(.center)
            .lineSpacing(6)
    }

    private var dividerLine: some View {
        Rectangle()
            .fill(Color(red: 0.804, green: 0.769, blue: 0.788).opacity(0.3))
            .frame(width: 48, height: 1)
            .padding(.top, 28)
    }

    private var actionRow: some View {
        HStack(spacing: 40) {
            Button(action: onSave) {
                VStack(spacing: 12) {
                    Image("icon-save-glass").resizable().aspectRatio(contentMode: .fit)
                        .frame(width: 47, height: 51)
                        .background(isSaved ? RoundedRectangle(cornerRadius: 14, style: .continuous).fill(LumiTheme.secondary.opacity(0.15)) : nil)
                        .scaleEffect(isSaved ? 1.05 : 1.0)
                    Text(isSaved ? "SAVED" : "SAVE")
                        .font(.custom("PlusJakartaSans-Regular", size: 9))
                        .foregroundStyle(isSaved ? LumiTheme.secondary : Color(red: 0.102, green: 0.110, blue: 0.102).opacity(0.4))
                        .kerning(0.9)
                }
            }
            Button(action: onShare) {
                VStack(spacing: 12) {
                    Image("icon-share-glass").resizable().aspectRatio(contentMode: .fit).frame(width: 51, height: 49)
                    Text("SHARE").font(.custom("PlusJakartaSans-Regular", size: 9))
                        .foregroundStyle(Color(red: 0.102, green: 0.110, blue: 0.102).opacity(0.4)).kerning(0.9)
                }
            }
            Button(action: onReport) {
                VStack(spacing: 12) {
                    Image("icon-report-glass").resizable().aspectRatio(contentMode: .fit).frame(width: 48, height: 50)
                    Text("REPORT").font(.custom("PlusJakartaSans-Regular", size: 9))
                        .foregroundStyle(Color(red: 0.102, green: 0.110, blue: 0.102).opacity(0.4)).kerning(0.9)
                }
            }
        }
        .padding(.top, 56)
    }
}

// MARK: - Swipe Onboarding

struct SwipeOnboarding: View {
    var onDismiss: () -> Void
    @State private var phase = 0
    @State private var arrowOffset: CGFloat = 0

    private let pink = Color(red: 0.925, green: 0.286, blue: 0.600)

    var body: some View {
        ZStack {
            // Glass backdrop
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .background(.ultraThinMaterial)

            VStack(spacing: 0) {
                Spacer()

                // Title
                Text("Swipe to Feel")
                    .font(LumiTheme.notoSerifDisplayLight(size: 36))
                    .foregroundStyle(.white)
                    .opacity(phase >= 1 ? 1 : 0)
                    .offset(y: phase >= 1 ? 0 : 20)
                    .padding(.bottom, 48)

                // Animated swipe indicators
                HStack(spacing: 0) {
                    // Left — skip
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(.white.opacity(0.08))
                                .frame(width: 64, height: 64)
                            Image(systemName: "hand.point.left.fill")
                                .font(.system(size: 24, weight: .light))
                                .foregroundStyle(.white.opacity(0.7))
                                .offset(x: -arrowOffset)
                        }

                        Text("NOT FOR ME")
                            .font(.custom("PlusJakartaSans-Regular", size: 10))
                            .fontWeight(.medium)
                            .foregroundStyle(.white.opacity(0.5))
                            .kerning(2)
                    }
                    .frame(maxWidth: .infinity)
                    .opacity(phase >= 2 ? 1 : 0)
                    .offset(x: phase >= 2 ? 0 : -30)

                    // Divider
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .white.opacity(0.2), .clear],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .frame(width: 1, height: 100)
                        .opacity(phase >= 2 ? 1 : 0)

                    // Right — love
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(pink.opacity(0.15))
                                .frame(width: 64, height: 64)
                            Image(systemName: "heart.fill")
                                .font(.system(size: 22, weight: .light))
                                .foregroundStyle(pink.opacity(0.8))
                                .offset(x: arrowOffset)
                        }

                        Text("LOVE THIS")
                            .font(.custom("PlusJakartaSans-Regular", size: 10))
                            .fontWeight(.medium)
                            .foregroundStyle(.white.opacity(0.5))
                            .kerning(2)
                    }
                    .frame(maxWidth: .infinity)
                    .opacity(phase >= 3 ? 1 : 0)
                    .offset(x: phase >= 3 ? 0 : 30)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)

                // Description
                Text("Swipe messages to share your energy.\nYour feedback shapes the\nsanctuary for everyone.")
                    .font(.custom("PlusJakartaSans-Regular", size: 13))
                    .foregroundStyle(.white.opacity(0.4))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .opacity(phase >= 3 ? 1 : 0)

                Spacer()

                // Button
                if phase >= 4 {
                    Button(action: onDismiss) {
                        Text("BEGIN")
                            .font(.custom("PlusJakartaSans-Regular", size: 13))
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .kerning(4)
                            .padding(.horizontal, 56)
                            .padding(.vertical, 18)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        Capsule(style: .continuous)
                                            .fill(.white.opacity(0.1))
                                    )
                                    .overlay(
                                        Capsule(style: .continuous)
                                            .stroke(.white.opacity(0.25), lineWidth: 1)
                                    )
                            )
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }

                Spacer().frame(height: 80)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.7).delay(0.2)) { phase = 1 }
            withAnimation(.easeOut(duration: 0.5).delay(0.6)) { phase = 2 }
            withAnimation(.easeOut(duration: 0.5).delay(1.0)) { phase = 3 }
            withAnimation(.easeOut(duration: 0.4).delay(1.6)) { phase = 4 }

            // Gentle pulsing arrow animation
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true).delay(1.2)) {
                arrowOffset = 4
            }
        }
    }
}

struct ReceiveMessageView_Previews: PreviewProvider {
    static var previews: some View {
        ReceiveMessageView()
    }
}
