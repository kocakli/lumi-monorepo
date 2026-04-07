import SwiftUI

// MARK: - PairsListView

struct PairsListView: View {
    @EnvironmentObject var router: AppRouter
    @StateObject private var viewModel = PairingViewModel()
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            stickyHeader
            scrollContent
        }
        .background(AuroraBackground())
        .offset(x: dragOffset)
        .simultaneousGesture(edgeSwipeGesture)
        .task { await viewModel.loadPairs() }
    }

    // MARK: - Sticky Header

    private var stickyHeader: some View {
        LumiHeader(
            subtitle: "PAIRED SOULS",
            leftIcon: "icon-close",
            onLeftTap: { router.goHome() },
            onRightTap: {}
        )
    }

    // MARK: - Scroll Content

    private var scrollContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 48) {
                heroSection
                cardsSection
                addNewPairButton
            }
            .padding(.horizontal, 24)
            .padding(.top, 40)
            .padding(.bottom, 80)
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 20) {
            Text("pairs_list.title")
                .font(.custom("NotoSerif-Regular", size: 48))
                .tracking(-1.2)
                .foregroundStyle(LumiTheme.primary)
                .multilineTextAlignment(.center)
                .lineSpacing(12)

            Rectangle()
                .fill(Color(red: 0.992, green: 0.776, blue: 0.678))
                .frame(width: 48, height: 1)

            Text("pairs_list.subtitle")
                .font(.custom("PlusJakartaSans-Regular", size: 10))
                .foregroundStyle(LumiTheme.onSurfaceVariant)
                .tracking(2)
        }
    }

    // MARK: - Cards Section

    private var cardsSection: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .tint(LumiTheme.primary)
                    .padding(.top, 60)
            } else if viewModel.pairs.isEmpty {
                emptyStateCard
            } else {
                VStack(spacing: 32) {
                    ForEach(viewModel.pairs) { pair in
                        PairCard(pair: pair, viewModel: viewModel)
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateCard: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart.circle")
                .font(.system(size: 40, weight: .ultraLight))
                .foregroundStyle(LumiTheme.sparklePink)

            Text("pairs_list.empty.title")
                .font(.custom("NotoSerif-Regular", size: 24))
                .foregroundStyle(LumiTheme.primary)

            Text("pairs_list.empty.subtitle")
                .font(.custom("PlusJakartaSans-Regular", size: 14))
                .foregroundStyle(LumiTheme.onSurfaceVariant)
                .multilineTextAlignment(.center)
                .lineSpacing(6)

            Button(action: { router.navigate(to: .settings) }) {
                Text("pairs_list.pair_now")
                    .font(.custom("PlusJakartaSans-Regular", size: 12))
                    .tracking(1.2)
                    .foregroundStyle(LumiTheme.buttonText)
            }
            .padding(.horizontal, 33)
            .padding(.vertical, 17)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(LumiTheme.primaryContainer)
                    .shadow(
                        color: Color(red: 0.475, green: 0.314, blue: 0.239).opacity(0.06),
                        radius: 10, x: 0, y: 4
                    )
            )
        }
        .padding(41)
        .frame(maxWidth: .infinity)
        .zenGlass(cornerRadius: 28, opacity: 0.3)
    }

    // MARK: - Add New Pair Button

    private var addNewPairButton: some View {
        Button(action: { router.navigate(to: .settings) }) {
            Text("pairs_list.add_new")
                .font(.custom("PlusJakartaSans-Regular", size: 12))
                .tracking(1.2)
                .foregroundStyle(LumiTheme.buttonText)
        }
        .padding(.horizontal, 33)
        .padding(.vertical, 17)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                )
                .shadow(
                    color: Color(red: 0.475, green: 0.314, blue: 0.239).opacity(0.06),
                    radius: 10, x: 0, y: 4
                )
        )
        .padding(.top, 8)
    }

    // MARK: - Edge Swipe Gesture

    private var edgeSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                if value.startLocation.x < 25
                    && value.translation.width > 0
                    && abs(value.translation.width) > abs(value.translation.height) * 2 {
                    dragOffset = value.translation.width
                }
            }
            .onEnded { _ in
                if dragOffset > 120 {
                    router.goHome()
                } else {
                    withAnimation(.spring(response: 0.3)) { dragOffset = 0 }
                }
            }
    }
}

// MARK: - PairCard

private struct PairCard: View {
    let pair: PairedUser
    @ObservedObject var viewModel: PairingViewModel

    @State private var isEditingNickname = false
    @State private var editedNickname = ""
    @State private var showUnpairAlert = false
    @FocusState private var nicknameFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            headerRow
            if isEditingNickname {
                nicknameEditor
            }
            actionRow
        }
        .padding(33)
        .frame(maxWidth: .infinity, alignment: .leading)
        .zenGlass(cornerRadius: 28, opacity: 0.3)
        .alert("pairs_list.unpair_confirm.title", isPresented: $showUnpairAlert) {
            Button("common.cancel", role: .cancel) {}
            Button("pairs_list.unpair_confirm.title", role: .destructive) {
                Task { await viewModel.unpair(pair.id) }
            }
        } message: {
            Text("pairs_list.unpair_confirm.message")
        }
    }

    // MARK: - Header Row

    private var headerRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(pair.nickname ?? String(localized: "pairs_list.unnamed"))
                .font(.custom("NotoSerif-Regular", size: 24))
                .foregroundStyle(LumiTheme.onSurface)

            pairedBadge
        }
    }

    private var pairedBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(LumiTheme.sparklePink)
                .frame(width: 6, height: 6)

            Text("pairs_list.paired_badge")
                .font(.custom("PlusJakartaSans-Regular", size: 10))
                .tracking(1.2)
                .foregroundStyle(LumiTheme.sparklePink)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(LumiTheme.sparklePink.opacity(0.12))
        )
    }

    // MARK: - Nickname Editor

    private var nicknameEditor: some View {
        HStack(spacing: 12) {
            TextField("Enter nickname", text: $editedNickname)
                .font(.custom("PlusJakartaSans-Regular", size: 14))
                .foregroundStyle(LumiTheme.onSurface)
                .focused($nicknameFieldFocused)
                .onChange(of: editedNickname) { _, newValue in
                    if newValue.count > 20 {
                        editedNickname = String(newValue.prefix(20))
                    }
                }
                .onSubmit { commitNickname() }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.4), lineWidth: 1)
                        )
                )

            Button(action: { commitNickname() }) {
                Text("common.save")
                    .font(.custom("PlusJakartaSans-Regular", size: 10))
                    .tracking(1)
                    .foregroundStyle(LumiTheme.buttonText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(LumiTheme.primaryContainer)
            )
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Action Row

    private var actionRow: some View {
        HStack(spacing: 16) {
            Button(action: {
                editedNickname = pair.nickname ?? ""
                withAnimation(.easeInOut(duration: 0.25)) {
                    isEditingNickname.toggle()
                }
                if isEditingNickname {
                    nicknameFieldFocused = true
                }
            }) {
                Text(isEditingNickname ? "common.cancel" : "pairs_list.rename")
                    .font(.custom("PlusJakartaSans-Regular", size: 10))
                    .tracking(1.2)
                    .foregroundStyle(LumiTheme.buttonText)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.4), lineWidth: 1)
                    )
            )

            Button(action: { showUnpairAlert = true }) {
                Text("pairs_list.unpair")
                    .font(.custom("PlusJakartaSans-Regular", size: 10))
                    .tracking(1.2)
                    .foregroundStyle(Color(red: 0.729, green: 0.102, blue: 0.102))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(red: 0.729, green: 0.102, blue: 0.102).opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color(red: 0.729, green: 0.102, blue: 0.102).opacity(0.15), lineWidth: 1)
                    )
            )

            Spacer()
        }
    }

    // MARK: - Helpers

    private func commitNickname() {
        let trimmed = editedNickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        Task { await viewModel.setNickname(for: pair.id, nickname: trimmed) }
        withAnimation(.easeInOut(duration: 0.25)) {
            isEditingNickname = false
        }
    }
}

// MARK: - Preview

struct PairsListView_Previews: PreviewProvider {
    static var previews: some View {
        PairsListView()
            .environmentObject(AppRouter())
    }
}
