import SwiftUI

// MARK: - Data Model

struct VaultMoment: Identifiable {
    let id: String
    let date: String
    let quote: String
    let tags: [String]
    let imageName: String?
}

// MARK: - VaultView

struct VaultView: View {
    @EnvironmentObject var router: AppRouter
    @StateObject private var viewModel = VaultViewModel()
    @State private var dragOffset: CGFloat = 0
    @State private var shareItem: ShareItem?

    var body: some View {
        VStack(spacing: 0) {
            vaultHeader
            scrollContent
        }
        .background(
            ZStack {
                LumiTheme.background

                Circle()
                    .fill(LumiTheme.primaryContainer)
                    .frame(width: 600, height: 600)
                    .blur(radius: 60)
                    .opacity(0.6)
                    .offset(x: -192, y: -192)

                Circle()
                    .fill(LumiTheme.peachGlow)
                    .frame(width: 500, height: 500)
                    .blur(radius: 60)
                    .opacity(0.4)
                    .offset(x: 150, y: 400)
            }
            .ignoresSafeArea()
        )
        .offset(x: dragOffset)
        .simultaneousGesture(
            DragGesture(minimumDistance: 20)
                .onChanged { value in
                    if value.startLocation.x < 25
                        && value.translation.width > 0
                        && abs(value.translation.width) > abs(value.translation.height) * 2 {
                        dragOffset = value.translation.width
                    }
                }
                .onEnded { value in
                    if dragOffset > 120 {
                        router.goHome()
                    } else {
                        withAnimation(.spring(response: 0.3)) { dragOffset = 0 }
                    }
                }
        )
        .onAppear { viewModel.startListening() }
        .onDisappear { viewModel.stopListening() }
        .sheet(item: $shareItem) { item in
            ShareMessageView(message: item.message, mood: item.mood)
        }
    }

    // MARK: - Header

    private var vaultHeader: some View {
        LumiHeader(
            subtitle: "THE VAULT",
            leftIcon: "icon-close",
            onLeftTap: { router.goHome() },
            onRightTap: { router.navigate(to: .settings) }
        )
    }

    // MARK: - Scroll Content

    private var scrollContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 48) {
                heroSection
                cardsSection
            }
            .padding(.horizontal, 24)
            .padding(.top, 40)
            .padding(.bottom, 80)
        }
    }

    private var heroSection: some View {
        VStack(spacing: 20) {
            Text("vault.title")
                .font(LumiTheme.notoSerifDisplay(size: 48, weight: 400))
                .foregroundStyle(LumiTheme.primary)
                .multilineTextAlignment(.center)
                .lineSpacing(12)

            Rectangle()
                .fill(Color(red: 0.992, green: 0.776, blue: 0.678))
                .frame(width: 48, height: 1)

            Text("vault.subtitle")
                .font(.custom("PlusJakartaSans-Regular", size: 11))
                .foregroundStyle(Color(red: 0.349, green: 0.373, blue: 0.400))
                .kerning(3.3)
        }
    }

    private var cardsSection: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .tint(LumiTheme.primary)
                    .padding(.top, 60)
            } else if viewModel.moments.isEmpty {
                VStack(spacing: 12) {
                    Text("vault.empty.title")
                        .font(LumiTheme.notoSerifDisplayLight(size: 20))
                        .foregroundStyle(LumiTheme.primary)
                    Text("vault.empty.subtitle")
                        .font(.custom("PlusJakartaSans-Regular", size: 14))
                        .foregroundStyle(LumiTheme.mutedText)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 60)
            } else {
                VStack(spacing: 44) {
                    ForEach(viewModel.moments) { moment in
                        VaultTextCard(
                            moment: moment,
                            onShare: {
                                shareItem = ShareItem(
                                    message: moment.quote,
                                    mood: moment.tags.first ?? "Peaceful"
                                )
                            },
                            onDelete: { Task { await viewModel.delete(momentId: moment.id) } }
                        )
                    }
                }
            }
        }
    }
}

// MARK: - VaultTextCard

private struct VaultTextCard: View {
    let moment: VaultMoment
    var onShare: () -> Void = {}
    var onDelete: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            dateRow
            quoteText
            tagsAndActions
        }
        .padding(41)
        .zenGlassCard()
    }

    private var dateRow: some View {
        HStack(spacing: 6) {
            Text(moment.date)
                .font(.custom("PlusJakartaSans-Regular", size: 10))
                .foregroundStyle(Color(red: 0.102, green: 0.110, blue: 0.102).opacity(0.6))
                .kerning(1)
            Image("icon-sparkle-tiny")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 12, height: 12)
        }
    }

    private var quoteText: some View {
        Text("\u{201C}\(moment.quote)\u{201D}")
            .font(LumiTheme.notoSerifDisplay(size: 24, weight: 400))
            .foregroundStyle(Color(red: 0.294, green: 0.271, blue: 0.286))
            .lineSpacing(15)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var tagsAndActions: some View {
        HStack {
            if !moment.tags.isEmpty {
                HStack(spacing: 12) {
                    ForEach(moment.tags, id: \.self) { tag in
                        VaultTagPill(text: tag)
                    }
                }
            }

            Spacer()

            HStack(spacing: 20) {
                Button(action: onShare) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(LumiTheme.mutedText)
                }

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(LumiTheme.mutedText)
                }
            }
        }
        .padding(.top, 16)
    }
}

// MARK: - VaultImageCard

private struct VaultImageCard: View {
    let moment: VaultMoment
    let imageName: String

    var body: some View {
        VStack(spacing: 32) {
            photoSection
            textSection
        }
        .padding(17)
        .zenGlassCard()
    }

    private var photoSection: some View {
        ZStack(alignment: .bottom) {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 231)
                .frame(maxWidth: .infinity)
                .clipped()

            LinearGradient(
                colors: [Color.black.opacity(0.2), Color.clear],
                startPoint: .bottom,
                endPoint: .top
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
    }

    private var textSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 6) {
                Text(moment.date)
                    .font(.custom("PlusJakartaSans-Regular", size: 10))
                    .foregroundStyle(Color(red: 0.102, green: 0.110, blue: 0.102).opacity(0.6))
                    .kerning(1)
                Image("icon-sparkle-tiny")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 12, height: 12)
            }

            Text("\u{201C}\(moment.quote)\u{201D}")
                .font(LumiTheme.notoSerifDisplay(size: 24, weight: 400))
                .foregroundStyle(Color(red: 0.294, green: 0.271, blue: 0.286))
                .lineSpacing(15)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }
}

// MARK: - VaultTagPill

private struct VaultTagPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.custom("PlusJakartaSans-Regular", size: 10))
            .foregroundStyle(Color(red: 0.294, green: 0.271, blue: 0.286))
            .kerning(0.5)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(Color(red: 0.957, green: 0.953, blue: 0.945))
            )
    }
}

// MARK: - Zen Glass Card Modifier

private struct ZenGlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 48, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 48, style: .continuous)
                            .fill(Color.white.opacity(0.3))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 48, style: .continuous)
                            .stroke(Color.white.opacity(0.6), lineWidth: 1)
                    )
            )
            .shadow(
                color: Color(red: 0.475, green: 0.314, blue: 0.239).opacity(0.06),
                radius: 25, x: 0, y: 20
            )
    }
}

private extension View {
    func zenGlassCard() -> some View {
        modifier(ZenGlassCardModifier())
    }
}

// MARK: - Share Item

struct ShareItem: Identifiable {
    let id = UUID()
    let message: String
    let mood: String
}

struct VaultView_Previews: PreviewProvider {
    static var previews: some View {
        VaultView()
    }
}
