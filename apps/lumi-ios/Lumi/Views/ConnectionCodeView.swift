import SwiftUI

struct ConnectionCodeView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PairingViewModel()
    @State private var codeCopied = false

    var body: some View {
        ZStack(alignment: .top) {
            AuroraBackground()
            scrollContent
            stickyHeader

            if viewModel.pairingSuccess {
                pairingSuccessOverlay
                    .zIndex(10)
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            await viewModel.loadMyCode()
        }
        .task {
            await viewModel.loadRequests()
        }
    }

    // MARK: - Sticky Header

    private var stickyHeader: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image("icon-close")
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 19, height: 19)
                    .foregroundStyle(LumiTheme.buttonText)
            }

            Spacer()

            Text("common.lumi")
                .font(.custom("NotoSerif-Regular", size: 24))
                .foregroundStyle(LumiTheme.onSurface)
                .tracking(-0.6)

            Spacer()

            Image("icon-lock-header")
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 15, height: 19.5)
                .foregroundStyle(LumiTheme.buttonText)
        }
        .padding(.horizontal, 32)
        .frame(height: 80)
        .background(
            Color(red: 0.98, green: 0.98, blue: 0.96)
                .opacity(0.3)
                .background(.ultraThinMaterial)
        )
    }

    // MARK: - Scroll Content

    private var scrollContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                titleSection
                yourCodeSection
                inputSection
                incomingRequestsSection
                infoSection
                bottomArt
            }
            .padding(.horizontal, 24)
            .padding(.top, 128)
            .padding(.bottom, 160)
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(spacing: 20) {
            titleText
            subtitleText
        }
        .padding(.bottom, 48)
    }

    private var titleText: some View {
        Text("pair.title")
            .font(.custom("NotoSerif-Regular", size: 48))
            .foregroundStyle(LumiTheme.primary)
            .tracking(-1.2)
            .multilineTextAlignment(.center)
            .lineSpacing(60 - 48)
    }

    private var subtitleText: some View {
        Text("pair.subtitle")
            .font(.custom("PlusJakartaSans-Regular", size: 16))
            .foregroundStyle(LumiTheme.onSurfaceVariant.opacity(0.8))
            .multilineTextAlignment(.center)
            .lineSpacing(26 - 16)
    }

    // MARK: - Your Code Section

    private var yourCodeSection: some View {
        VStack(spacing: 0) {
            Text("pair.your_code")
                .font(.custom("PlusJakartaSans-Regular", size: 10))
                .foregroundStyle(Color(red: 0.349, green: 0.373, blue: 0.400))
                .tracking(2)
                .padding(.bottom, 24)

            if viewModel.isLoadingCode {
                codeSkeletonView
            } else {
                Text(viewModel.myCode.isEmpty ? "------" : viewModel.myCode)
                    .font(.system(size: 30, design: .monospaced))
                    .foregroundStyle(LumiTheme.onSurface)
                    .tracking(3)
            }

            copyButton
                .padding(.top, 24)
        }
        .padding(49)
        .zenGlass(cornerRadius: 48, opacity: 0.3)
        .padding(.bottom, 48)
    }

    private var codeSkeletonView: some View {
        HStack(spacing: 6) {
            ForEach(0..<9, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(LumiTheme.onSurfaceVariant.opacity(0.1))
                    .frame(width: 18, height: 28)
            }
        }
        .shimmering()
    }

    private var copyButton: some View {
        Button(action: {
            UIPasteboard.general.string = viewModel.myCode
            withAnimation(.easeInOut(duration: 0.2)) {
                codeCopied = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    codeCopied = false
                }
            }
        }) {
            Text(codeCopied ? "common.copied" : "common.copy")
                .font(.custom("PlusJakartaSans-Regular", size: 12))
                .fontWeight(.semibold)
                .foregroundStyle(Color(red: 0.459, green: 0.427, blue: 0.451))
                .tracking(1.4)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(
                    Capsule(style: .continuous)
                        .fill(LumiTheme.primaryContainer)
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                        )
                )
        }
        .disabled(viewModel.myCode.isEmpty || viewModel.isLoadingCode)
        .opacity(viewModel.myCode.isEmpty || viewModel.isLoadingCode ? 0.5 : 1)
    }

    // MARK: - Input Section

    private var inputSection: some View {
        VStack(spacing: 48) {
            zenInputCard
            syncButton
            feedbackMessages
        }
    }

    private var zenInputCard: some View {
        VStack(spacing: 0) {
            Text("pair.enter_code")
                .font(.custom("PlusJakartaSans-Regular", size: 10))
                .foregroundStyle(Color(red: 0.349, green: 0.373, blue: 0.400))
                .tracking(2)
                .padding(.bottom, 32)

            syncTextField
        }
        .padding(49)
        .zenGlass(cornerRadius: 48, opacity: 0.3)
    }

    private var syncTextField: some View {
        TextField("", text: $viewModel.friendCode, prompt:
            Text("LUMI-XXXX")
                .font(.system(size: 30, design: .monospaced))
                .foregroundStyle(Color(red: 0.42, green: 0.45, blue: 0.50).opacity(0.2))
        )
        .font(.system(size: 30, design: .monospaced))
        .foregroundStyle(LumiTheme.onSurface)
        .tracking(3)
        .multilineTextAlignment(.center)
        .textInputAutocapitalization(.characters)
        .autocorrectionDisabled()
        .padding(.top, 28)
        .padding(.bottom, 20)
        .padding(.horizontal, 12)
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.08), radius: 1, x: 0, y: 1)
    }

    private var syncButton: some View {
        Button(action: {
            Task { await viewModel.sendRequest() }
        }) {
            HStack(spacing: 10) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(Color(red: 0.459, green: 0.427, blue: 0.451))
                }
                Text("pair.sync")
                    .font(.custom("PlusJakartaSans-Regular", size: 14))
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(red: 0.459, green: 0.427, blue: 0.451))
                    .tracking(1.4)
            }
            .padding(.horizontal, 49)
            .padding(.vertical, 21)
            .background(
                Capsule(style: .continuous)
                    .fill(LumiTheme.primaryContainer)
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                    )
            )
            .shadow(
                color: Color(red: 0.475, green: 0.314, blue: 0.239).opacity(0.1),
                radius: 20, x: 0, y: 15
            )
        }
        .disabled(viewModel.friendCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
        .opacity(viewModel.friendCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1)
    }

    private var feedbackMessages: some View {
        VStack(spacing: 8) {
            if let error = viewModel.error {
                Text(error)
                    .font(.custom("PlusJakartaSans-Regular", size: 14))
                    .foregroundStyle(Color(red: 0.8, green: 0.2, blue: 0.2))
                    .multilineTextAlignment(.center)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                viewModel.error = nil
                            }
                        }
                    }
            }

            if let success = viewModel.successMessage {
                Text(success)
                    .font(.custom("PlusJakartaSans-Regular", size: 14))
                    .foregroundStyle(Color(red: 0.2, green: 0.6, blue: 0.4))
                    .multilineTextAlignment(.center)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                viewModel.successMessage = nil
                            }
                        }
                    }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.error)
        .animation(.easeInOut(duration: 0.3), value: viewModel.successMessage)
    }

    // MARK: - Incoming Requests Section

    @ViewBuilder
    private var incomingRequestsSection: some View {
        if !viewModel.incomingRequests.isEmpty {
            VStack(spacing: 24) {
                Text("pair.requests")
                    .font(.custom("PlusJakartaSans-Regular", size: 10))
                    .foregroundStyle(Color(red: 0.349, green: 0.373, blue: 0.400))
                    .tracking(2)
                    .padding(.top, 64)

                ForEach(viewModel.incomingRequests) { request in
                    requestCard(for: request)
                }
            }
        }
    }

    private func requestCard(for request: PairRequest) -> some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                if !request.fromUserCode.isEmpty {
                    Text(request.fromUserCode)
                        .font(.system(size: 20, design: .monospaced))
                        .foregroundStyle(LumiTheme.secondary)
                        .tracking(2)
                }
                Text("pair.wants_to_pair")
                    .font(.custom("PlusJakartaSans-Regular", size: 16))
                    .foregroundStyle(LumiTheme.onSurface)
            }
            .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                Button(action: {
                    Task { await viewModel.acceptRequest(request.id) }
                }) {
                    Text("pair.accept")
                        .font(.custom("PlusJakartaSans-Regular", size: 12))
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .tracking(1.2)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(
                            Capsule(style: .continuous)
                                .fill(LumiTheme.sparklePink)
                                .overlay(
                                    Capsule(style: .continuous)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .shadow(
                            color: LumiTheme.sparklePink.opacity(0.3),
                            radius: 12, x: 0, y: 8
                        )
                }

                Button(action: {
                    Task { await viewModel.rejectRequest(request.id) }
                }) {
                    Text("pair.decline")
                        .font(.custom("PlusJakartaSans-Regular", size: 12))
                        .fontWeight(.semibold)
                        .foregroundStyle(LumiTheme.onSurfaceVariant)
                        .tracking(1.2)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(
                            Capsule(style: .continuous)
                                .fill(LumiTheme.surfaceLow)
                                .overlay(
                                    Capsule(style: .continuous)
                                        .stroke(LumiTheme.outlineVariant.opacity(0.5), lineWidth: 1)
                                )
                        )
                }
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .zenGlass(cornerRadius: 28, opacity: 0.3)
    }

    // MARK: - Info Section

    private var infoSection: some View {
        VStack(spacing: 48) {
            securityInfoItem
            connectionInfoItem
        }
        .padding(.top, 128)
    }

    private var securityInfoItem: some View {
        VStack(spacing: 16) {
            glassCircleIcon(imageName: "icon-lock", width: 16, height: 20)
            infoLabel("SECURITY")
            infoDescription("Your code is unique to you. Sharing it is an act of trust, and the bond remains anonymous.")
        }
    }

    private var connectionInfoItem: some View {
        VStack(spacing: 16) {
            glassCircleIcon(imageName: "icon-connection", width: 22, height: 22)
            infoLabel("CONNECTION")
            infoDescription("Once connected, you and your pair will softly sense each other's presence within the sanctuary.")
        }
    }

    private func glassCircleIcon(imageName: String, width: CGFloat, height: CGFloat) -> some View {
        Image(imageName)
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: width, height: height)
            .foregroundStyle(LumiTheme.buttonText)
            .frame(width: 56, height: 56)
            .zenGlass(cornerRadius: 28, opacity: 0.3)
    }

    private func infoLabel(_ text: String) -> some View {
        Text(text)
            .font(.custom("PlusJakartaSans-Regular", size: 12))
            .fontWeight(.semibold)
            .foregroundStyle(Color(red: 0.102, green: 0.110, blue: 0.102))
            .tracking(1.2)
    }

    private func infoDescription(_ text: String) -> some View {
        Text(text)
            .font(.custom("PlusJakartaSans-Regular", size: 12))
            .foregroundStyle(LumiTheme.onSurfaceVariant)
            .multilineTextAlignment(.center)
            .lineSpacing(19.5 - 12)
            .padding(.horizontal, 24)
    }

    // MARK: - Bottom Art

    private var bottomArt: some View {
        Image("abstract-art-circle")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 128, height: 128)
            .clipShape(Circle())
            .opacity(0.3)
            .blendMode(.multiply)
            .padding(.top, 96)
    }

    // MARK: - Pairing Success Overlay

    private var pairingSuccessOverlay: some View {
        PairingSuccessAnimation(isPresented: $viewModel.pairingSuccess)
    }
}

// MARK: - Shimmer Effect

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0),
                        Color.white.opacity(0.4),
                        Color.white.opacity(0)
                    ],
                    startPoint: .init(x: phase - 0.5, y: 0.5),
                    endPoint: .init(x: phase + 0.5, y: 0.5)
                )
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1.5
                }
            }
    }
}

extension View {
    func shimmering() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Preview

struct ConnectionCodeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ConnectionCodeView()
        }
    }
}
