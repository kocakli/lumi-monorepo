import SwiftUI

// MARK: - Lumi Design System (Zen Garden / Digital Sanctuary)

enum LumiTheme {

    // MARK: - Colors (from Figma)

    /// Background base: warm off-white cream (#FAF9F6)
    static let background = Color(red: 0.98, green: 0.976, blue: 0.965)

    /// Primary text: dusty charcoal (#635C61)
    static let primary = Color(red: 0.388, green: 0.361, blue: 0.380)

    /// Primary container: pale cherry blossom (#FDF2F8)
    static let primaryContainer = Color(red: 0.992, green: 0.949, blue: 0.973)

    /// Secondary: soft peach (#7E5541)
    static let secondary = Color(red: 0.494, green: 0.333, blue: 0.255)

    /// Secondary container: peach glow (#FDC6AD)
    static let secondaryContainer = Color(red: 0.992, green: 0.776, blue: 0.678)

    /// On-surface: warm near-black (#292524) - from Figma
    static let onSurface = Color(red: 0.161, green: 0.145, blue: 0.141)

    /// On-surface variant: muted (#4B4549)
    static let onSurfaceVariant = Color(red: 0.294, green: 0.271, blue: 0.286)

    /// Button text: warm stone (#44403C) - from Figma
    static let buttonText = Color(red: 0.267, green: 0.251, blue: 0.235)

    /// Muted text: stone gray (#78716C) - from Figma
    static let mutedText = Color(red: 0.471, green: 0.443, blue: 0.424)

    /// Sparkle pink: (#FDA4AF) - from Figma
    static let sparklePink = Color(red: 0.992, green: 0.643, blue: 0.686)

    /// Outline variant: soft border (#CDC4C9)
    static let outlineVariant = Color(red: 0.804, green: 0.769, blue: 0.788)

    /// Surface container lowest: pure white (#FFFFFF)
    static let surfaceLowest = Color.white

    /// Surface container low: subtle depth (#F4F3F1)
    static let surfaceLow = Color(red: 0.957, green: 0.953, blue: 0.945)

    /// Surface container high (#E9E8E5)
    static let surfaceHigh = Color(red: 0.914, green: 0.910, blue: 0.898)

    /// Tertiary container: cool blue-gray (#EFF5FD)
    static let tertiaryContainer = Color(red: 0.937, green: 0.961, blue: 0.992)

    /// Peach warm gradient color (#FFDBCC)
    static let peachGlow = Color(red: 1.0, green: 0.859, blue: 0.800)

    /// Bottom bar active link bg (#FFF1F2 at 50%)
    static let activeLink = Color(red: 1.0, green: 0.945, blue: 0.949).opacity(0.5)

    // MARK: - Typography (Noto Serif + Plus Jakarta Sans)
    // Variable fonts: use family name for .custom(), then .fontWeight() for weight variants
    // Figma uses: "Noto Serif: Display Light" for title, "Plus Jakarta Sans: Medium" for labels

    /// Display large - Noto Serif Display Light
    /// Figma: fontVariationSettings 'CTGR' 100, 'wdth' 100, weight Light (300)
    static func displayLarge(_ size: CGFloat = 80) -> Font {
        notoSerifDisplay(size: size, weight: 300)
    }

    /// Noto Serif Display Light - for message text (30px)
    static func notoSerifDisplayLight(size: CGFloat) -> Font {
        notoSerifDisplay(size: size, weight: 300)
    }

    /// Headline - Noto Serif for messages and quotes
    static func headline(_ size: CGFloat = 28) -> Font {
        .custom("NotoSerif-Regular", size: size, relativeTo: .title)
    }

    /// Noto Serif Display with explicit variation axes (CTGR, wght, wdth)
    static func notoSerifDisplay(size: CGFloat, weight: CGFloat) -> Font {
        guard let base = UIFont(name: "NotoSerifDisplay-Regular", size: size) else {
            return .custom("NotoSerifDisplay-Regular", size: size)
        }
        // Variable font axes from Figma:
        // wght (0x77676874) = weight, CTGR (0x43544752) = category, wdth (0x77647468) = width
        let descriptor = base.fontDescriptor.addingAttributes([
            UIFontDescriptor.AttributeName(rawValue: "NSCTFontVariationAttribute"): [
                0x77676874: weight, // wght: 300 = Light
                0x43544752: 100,    // CTGR: 100 = Display style
                0x77647468: 100     // wdth: 100 = Normal width
            ]
        ])
        return Font(UIFont(descriptor: descriptor, size: size))
    }

    /// Label - Plus Jakarta Sans (use .fontWeight(.medium) for Medium)
    static func label(_ size: CGFloat = 11) -> Font {
        .custom("PlusJakartaSans-Regular", size: size, relativeTo: .caption)
    }

    /// Body text - Plus Jakarta Sans Regular
    static func body(_ size: CGFloat = 16) -> Font {
        .custom("PlusJakartaSans-Regular", size: size, relativeTo: .body)
    }

    /// Body Medium - Plus Jakarta Sans (use .fontWeight(.medium))
    static func bodyMedium(_ size: CGFloat = 14) -> Font {
        .custom("PlusJakartaSans-Regular", size: size, relativeTo: .body)
    }

    // MARK: - Shadows (pink-tinted from Figma: rgba(121,80,61,0.06))

    static let ambientShadow = Color(red: 0.475, green: 0.314, blue: 0.239).opacity(0.06)
    static let cardShadow = Color(red: 0.475, green: 0.314, blue: 0.239).opacity(0.06)

    // MARK: - Corner Radius

    static let radiusSmall: CGFloat = 12
    static let radiusMedium: CGFloat = 20
    static let radiusLarge: CGFloat = 28
    static let radiusXL: CGFloat = 36
    static let radiusFull: CGFloat = 9999
}

// MARK: - Aurora Gradient Background (matches Figma exactly)

struct AuroraBackground: View {
    var body: some View {
        ZStack {
            LumiTheme.background
                .ignoresSafeArea()

            // Cherry blossom pink radial - top left (from Figma: cx=78, cy=265.2)
            RadialGradient(
                colors: [LumiTheme.primaryContainer, LumiTheme.primaryContainer.opacity(0)],
                center: UnitPoint(x: 0.2, y: 0.3),
                startRadius: 0,
                endRadius: 350
            )
            .ignoresSafeArea()

            // Peach warm radial - bottom right (from Figma: cx=312, cy=618.8)
            RadialGradient(
                colors: [LumiTheme.peachGlow, LumiTheme.peachGlow.opacity(0)],
                center: UnitPoint(x: 0.8, y: 0.7),
                startRadius: 0,
                endRadius: 350
            )
            .ignoresSafeArea()

            // Decorative blur blob - top left (from Figma: 234x530, blur 60, opacity 40%)
            Circle()
                .fill(LumiTheme.primaryContainer)
                .frame(width: 234, height: 530)
                .blur(radius: 60)
                .opacity(0.4)
                .offset(x: -100, y: -200)
                .ignoresSafeArea()

            // Decorative blur blob - bottom right (from Figma: 195x442, blur 60, opacity 30%)
            Circle()
                .fill(LumiTheme.peachGlow)
                .frame(width: 195, height: 442)
                .blur(radius: 60)
                .opacity(0.3)
                .offset(x: 100, y: 200)
                .ignoresSafeArea()
        }
    }
}

// MARK: - Zen Glass Material (from Figma: backdrop-blur 20, white 30%/40%, border white 60%)

struct ZenGlass: ViewModifier {
    var cornerRadius: CGFloat = LumiTheme.radiusFull
    var opacity: Double = 0.3

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(Color.white.opacity(opacity))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.white.opacity(0.6), lineWidth: 1)
                    )
            )
            .shadow(color: LumiTheme.ambientShadow, radius: 25, x: 0, y: 20)
    }
}

extension View {
    func zenGlass(cornerRadius: CGFloat = LumiTheme.radiusFull, opacity: Double = 0.3) -> some View {
        modifier(ZenGlass(cornerRadius: cornerRadius, opacity: opacity))
    }
}

// MARK: - Global Header (consistent across all pages)

struct LumiHeader: View {
    var subtitle: String? = nil
    var leftIcon: String = "icon-settings"
    var onLeftTap: (() -> Void)? = nil
    var onRightTap: (() -> Void)? = nil

    var body: some View {
        HStack {
            Button(action: { onLeftTap?() }) {
                Image(leftIcon)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 19, height: 19)
                    .foregroundStyle(LumiTheme.buttonText)
            }

            Spacer()

            VStack(spacing: 2) {
                Text("Lumi")
                    .font(.custom("NotoSerif-Regular", size: 36))
                    .foregroundStyle(LumiTheme.onSurface)
                    .transformEffect(CGAffineTransform(a: 1, b: 0, c: -0.18, d: 1, tx: 0, ty: 0))

                if let subtitle {
                    Text(subtitle.uppercased())
                        .font(.custom("PlusJakartaSans-Regular", size: 10))
                        .foregroundStyle(LumiTheme.mutedText.opacity(0.6))
                        .kerning(1)
                }
            }

            Spacer()

            Button(action: { onRightTap?() }) {
                Image("icon-shelves")
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 17, height: 21)
                    .foregroundStyle(LumiTheme.buttonText)
            }
        }
        .padding(.horizontal, 32)
        .padding(.top, 24)
        .padding(.bottom, 16)
        .background(
            Color.white.opacity(0.3)
                .background(.ultraThinMaterial)
                .ignoresSafeArea(edges: .top)
        )
    }
}

// MARK: - Glassmorphic Nav Icon (from Figma: circle with backdrop blur)

struct GlassNavIcon: View {
    let iconName: String
    var width: CGFloat = 19
    var height: CGFloat = 19

    var body: some View {
        if #available(iOS 26, *) {
            Image(iconName)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: width, height: height)
                .foregroundStyle(LumiTheme.buttonText)
                .padding(13)
                .glassEffect(.regular.interactive(), in: .circle)
        } else {
            Image(iconName)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: width, height: height)
                .foregroundStyle(LumiTheme.buttonText)
                .padding(13)
                .zenGlass(cornerRadius: LumiTheme.radiusFull, opacity: 0.3)
        }
    }
}

// MARK: - Floating Bottom Bar (from Figma node 1:154)
// Figma: backdrop-blur 20, bg white 30%, border white 60%, rounded-48
// pl-9 pr-11.8 py-9, gap-2.8, shadow 0 20 50 rgba(121,80,61,0.06)
// Left: icon-add 51x51 (original render, #A8A29E)
// Right: icon-sparkle-nav 52x52 (original render, pink bg + dark sparkle), scale 90%

struct FloatingBottomBar: View {
    var onAddTap: () -> Void = {}
    var onSparkTap: () -> Void = {}
    var sparkleActive: Bool = false

    var body: some View {
        barContent
    }

    private var barContent: some View {
        HStack(spacing: 2.8) {
            Button(action: onAddTap) {
                Image("icon-add")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 51, height: 51)
            }

            Button(action: onSparkTap) {
                Image("icon-sparkle-nav")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 52, height: 52)
                    .scaleEffect(0.9)
            }
            .frame(height: 58)
            .background(
                sparkleActive
                    ? Circle().fill(LumiTheme.primaryContainer.opacity(0.7))
                    : Circle().fill(Color.clear)
            )
        }
        .padding(.leading, 9)
        .padding(.trailing, 12)
        .padding(.vertical, 9)
        .background(barBackground)
        .shadow(
            color: Color(red: 0.475, green: 0.314, blue: 0.239).opacity(0.06),
            radius: 25, x: 0, y: 20
        )
    }

    @ViewBuilder
    private var barBackground: some View {
        if #available(iOS 26, *) {
            RoundedRectangle(cornerRadius: 48, style: .continuous)
                .fill(.clear)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 48))
        } else {
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
        }
    }
}

// MARK: - Uppercase Label Style

struct ZenLabel: View {
    let text: String
    var size: CGFloat = 11
    var color: Color = LumiTheme.onSurfaceVariant

    var body: some View {
        Text(text.uppercased())
            .font(LumiTheme.label(size))
            .fontWeight(.medium)
            .foregroundStyle(color)
            .kerning(1.5)
    }
}

// MARK: - Mood Pill Tag

struct MoodPill: View {
    let mood: String
    var showIcon: Bool = true

    var body: some View {
        HStack(spacing: 6) {
            if showIcon {
                Image("icon-sparkle")
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 12, height: 12)
                    .foregroundStyle(LumiTheme.sparklePink)
            }
            Text(mood.uppercased())
                .font(LumiTheme.label(10))
                .kerning(1.2)
        }
        .foregroundStyle(LumiTheme.onSurfaceVariant)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(LumiTheme.surfaceLowest.opacity(0.8))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        )
    }
}
