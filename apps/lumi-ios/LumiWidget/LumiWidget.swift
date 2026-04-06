import WidgetKit
import SwiftUI

// MARK: - Data Model

struct LumiEntry: TimelineEntry {
    let date: Date
    let message: String
    let currentIndex: Int    // 0-4, which of the 5 messages is active
    let totalCount: Int      // always 5
}

// MARK: - Shared Data

private enum SharedData {
    static let suiteName = "group.com.tease.lumi"
    static let messagesKey = "widget_messages"
    static let messageCount = 5

    static let fallbackMessages = [
        "Even the smallest star shines in the darkest night.",
        "The world is better because you chose to be kind today.",
        "Breathe in calm, breathe out worry. This moment is yours.",
        "You are doing better than you think.",
        "The kindness you show others always finds its way back.",
        "In the quiet moments, remember: you are enough.",
        "Your smile has the power to change someone's entire day.",
        "Courage is not the absence of fear. It is taking the next step anyway.",
        "Today, give yourself permission to rest. You have earned it.",
        "A single act of kindness throws out roots in all directions.",
        "Somewhere in the world, someone is grateful that you exist.",
        "Let the soft things in life catch you when you fall.",
    ]

    static func loadMessages() -> [String] {
        let stored = UserDefaults(suiteName: suiteName)?.stringArray(forKey: messagesKey) ?? []
        return stored.isEmpty ? fallbackMessages : stored
    }

    /// Pick 5 unique random messages for a rotation cycle
    static func pickFive() -> [String] {
        let pool = loadMessages()
        var shuffled = pool.shuffled()
        // Ensure we always have at least 5
        while shuffled.count < messageCount {
            shuffled.append(contentsOf: pool.shuffled())
        }
        return Array(shuffled.prefix(messageCount))
    }
}

// MARK: - Timeline Provider

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> LumiEntry {
        LumiEntry(
            date: Date(),
            message: "The space you create for yourself is where your light begins to glow.",
            currentIndex: 0,
            totalCount: 5
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (LumiEntry) -> ()) {
        let messages = SharedData.loadMessages()
        completion(LumiEntry(
            date: Date(),
            message: messages.randomElement() ?? "You are enough.",
            currentIndex: 0,
            totalCount: 5
        ))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let fiveMessages = SharedData.pickFive()
        var entries: [LumiEntry] = []
        let currentDate = Date()

        // 5 messages, each shown for 30 seconds
        for i in 0..<5 {
            let entryDate = currentDate.addingTimeInterval(Double(i) * 30)
            entries.append(LumiEntry(
                date: entryDate,
                message: fiveMessages[i],
                currentIndex: i,
                totalCount: 5
            ))
        }

        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

// MARK: - Design Tokens (from Figma node 37:32)

private enum WT {
    // Aurora gradient 135deg
    static let grad0 = Color(red: 0.98, green: 0.976, blue: 0.965)       // #FAF9F6
    static let grad1 = Color(red: 0.992, green: 0.949, blue: 0.973)      // #FDF2F8
    static let grad2 = Color(red: 1.0, green: 0.859, blue: 0.800)        // #FFDBCC
    static let grad3 = Color(red: 0.918, green: 0.878, blue: 0.902)      // #EAE0E6

    // Text color — black
    static let text = Color.black

    // Branding "Lumi" rgba(121,80,61,0.7)
    static let brand = Color(red: 0.475, green: 0.314, blue: 0.239).opacity(0.7)

    // Divider rgba(253,198,173,0.6)
    static let divider = Color(red: 0.992, green: 0.776, blue: 0.678).opacity(0.6)

    // Accent dot #7E5541
    static let dot = Color(red: 0.494, green: 0.333, blue: 0.255)

    /// Noto Serif Display Light — variable font with wght=300, CTGR=100, wdth=100
    /// Same approach as LumiTheme.notoSerifDisplay() in the main app
    static func messageFont(size: CGFloat) -> Font {
        guard let base = UIFont(name: "NotoSerifDisplay-Regular", size: size) else {
            // Fallback if variable font not available
            return .system(size: size, weight: .light, design: .serif)
        }
        let descriptor = base.fontDescriptor.addingAttributes([
            UIFontDescriptor.AttributeName(rawValue: "NSCTFontVariationAttribute"): [
                0x77676874: 300,  // wght: 300 = Light
                0x43544752: 100,  // CTGR: 100 = Display style
                0x77647468: 100   // wdth: 100 = Normal width
            ]
        ])
        return Font(UIFont(descriptor: descriptor, size: size))
    }
}

// MARK: - Pagination Dots

private struct PaginationDots: View {
    let current: Int
    let total: Int

    var body: some View {
        VStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(WT.dot.opacity(index == current ? 1.0 : 0.2))
                    .frame(width: 5, height: 5)
                    .shadow(
                        color: index == current ? WT.dot.opacity(0.4) : .clear,
                        radius: index == current ? 4 : 0
                    )
            }
        }
    }
}

// MARK: - Widget View

struct LumiWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryRectangular:
            lockScreenRectangular
        case .accessoryInline:
            Text("\u{2728} " + entry.message)
        default:
            homeScreenWidget
        }
    }

    private var lockScreenRectangular: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Lumi")
                .font(.system(size: 12, weight: .light, design: .serif))
                .opacity(0.7)
            Text(entry.message)
                .font(.system(size: 13, weight: .regular, design: .serif))
                .lineLimit(3)
                .minimumScaleFactor(0.8)
        }
    }

    // MARK: - Home Screen Widget (all 3 sizes)

    private var homeScreenWidget: some View {
        // Glass pane with message content — fills the widget
        VStack(spacing: family == .systemLarge ? 16 : 12) {
            Spacer(minLength: 0)

            Text("\u{201C}\(entry.message)\u{201D}")
                .font(WT.messageFont(size: fontSize))
                .foregroundStyle(WT.text)
                .multilineTextAlignment(.center)
                .lineSpacing(lineSpacing)
                .lineLimit(maxLines)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 0)

            // Divider — Lumi — Divider
            HStack(spacing: 8) {
                Rectangle().fill(WT.divider).frame(width: 16, height: 1)
                Text("Lumi")
                    .font(.system(size: 13, design: .serif))
                    .italic()
                    .foregroundStyle(WT.brand)
                    .kerning(1.8)
                Rectangle().fill(WT.divider).frame(width: 16, height: 1)
            }
        }
        .padding(.horizontal, family == .systemSmall ? 12 : 20)
        .padding(.top, 8)
        .padding(.bottom, family == .systemSmall ? 6 : 2)
        .background(
            RoundedRectangle(cornerRadius: family == .systemSmall ? 20 : 28.8, style: .continuous)
                .fill(Color.white.opacity(0.35))
                .overlay(
                    RoundedRectangle(cornerRadius: family == .systemSmall ? 20 : 28.8, style: .continuous)
                        .stroke(Color.white.opacity(0.6), lineWidth: 1)
                )
        )
        // Dots overlaid at the trailing edge, outside the glass pane
        .overlay(alignment: .trailing) {
            PaginationDots(current: entry.currentIndex, total: entry.totalCount)
                .offset(x: family == .systemSmall ? 8 : 10)
        }
        .containerBackground(for: .widget) {
            ZStack {
                LinearGradient(
                    colors: [WT.grad0, WT.grad1, WT.grad2, WT.grad3],
                    startPoint: UnitPoint(x: 0, y: 0),
                    endPoint: UnitPoint(x: 1, y: 1)
                )
                RadialGradient(
                    colors: [WT.grad1.opacity(0.8), WT.grad1.opacity(0)],
                    center: UnitPoint(x: 0.3, y: 0.3),
                    startRadius: 0,
                    endRadius: 200
                )
                RadialGradient(
                    colors: [WT.grad2.opacity(0.6), WT.grad2.opacity(0)],
                    center: UnitPoint(x: 0.7, y: 0.7),
                    startRadius: 0,
                    endRadius: 200
                )
            }
        }
    }

    private var fontSize: CGFloat {
        switch family {
        case .systemSmall: return 15
        case .systemLarge: return 24
        default: return 18
        }
    }

    private var lineSpacing: CGFloat {
        switch family {
        case .systemSmall: return 5
        case .systemLarge: return 11
        default: return 7
        }
    }

    private var maxLines: Int {
        switch family {
        case .systemSmall: return 5
        case .systemLarge: return 14
        default: return 4
        }
    }
}

// MARK: - Widget

@main
struct LumiWidget: Widget {
    let kind: String = "LumiWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            LumiWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Lumi")
        .description("Positive messages throughout your day.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}
