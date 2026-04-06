import SwiftUI

struct ConnectionCodeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var syncCode: String = ""

    var body: some View {
        ZStack(alignment: .top) {
            AuroraBackground()
            scrollContent
            stickyHeader
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Sticky Header

    private var stickyHeader: some View {
        HStack {
            // Left: back button → returns to Settings
            Button(action: { dismiss() }) {
                Image("icon-close")
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 19, height: 19)
                    .foregroundStyle(LumiTheme.buttonText)
            }

            Spacer()

            // Center: "Lumi" serif title
            Text("Lumi")
                .font(.custom("NotoSerif-Regular", size: 24))
                .foregroundStyle(LumiTheme.onSurface)
                .tracking(-0.6)

            Spacer()

            // Right: lock icon (decorative)
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
                inputSection
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
        .padding(.bottom, 80)
    }

    private var titleText: some View {
        Text("Pair Your\nSanctuary")
            .font(.custom("NotoSerif-Regular", size: 48))
            .foregroundStyle(LumiTheme.primary)
            .tracking(-1.2)
            .multilineTextAlignment(.center)
            .lineSpacing(60 - 48) // line-height 60 minus font size
    }

    private var subtitleText: some View {
        Text("Connect with another soul by entering their private code. Once paired, your presence will be softly shared without revealing your identity.")
            .font(.custom("PlusJakartaSans-Regular", size: 16))
            .foregroundStyle(LumiTheme.onSurfaceVariant.opacity(0.8))
            .multilineTextAlignment(.center)
            .lineSpacing(26 - 16) // line-height 26 minus font size
    }

    // MARK: - Input Section

    private var inputSection: some View {
        VStack(spacing: 48) {
            zenInputCard
            syncButton
        }
    }

    private var zenInputCard: some View {
        VStack(spacing: 0) {
            // "ENTER SYNC CODE" label
            Text("ENTER SYNC CODE")
                .font(.custom("PlusJakartaSans-Regular", size: 10))
                .foregroundStyle(Color(red: 0.349, green: 0.373, blue: 0.400))
                .tracking(2)
                .padding(.bottom, 32)

            // Input field
            syncTextField
        }
        .padding(49)
        .zenGlass(cornerRadius: 48, opacity: 0.3)
    }

    private var syncTextField: some View {
        TextField("", text: $syncCode, prompt:
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
            // Sync action
        }) {
            Text("SYNC")
                .font(.custom("PlusJakartaSans-Regular", size: 14))
                .fontWeight(.semibold)
                .foregroundStyle(Color(red: 0.459, green: 0.427, blue: 0.451))
                .tracking(1.4)
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
            .lineSpacing(19.5 - 12) // line-height 19.5 minus font size
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
}

struct ConnectionCodeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ConnectionCodeView()
        }
    }
}
