import WidgetKit
import SwiftUI

// MARK: - Shared Cache Reader

/// Reads the same App Group cache that `WatchMessageStore` writes.
/// Cannot import the Watch app's source directly because the complication
/// is a separate target — duplicate the small reader here.
private enum WatchCache {
    static let suiteName = "group.com.tease.lumi.watch"
    static let messagesKey = "lumi.watch.messages"

    static let fallback: [String] = [
        "Even the smallest star shines in the darkest night.",
        "You are doing better than you think.",
        "Breathe in calm. Breathe out worry.",
        "In the quiet moments, remember: you are enough.",
        "Today, give yourself permission to rest.",
        "Somewhere, someone is grateful you exist.",
        "Be soft with yourself today.",
        "You are becoming, quietly and beautifully.",
    ]

    static func loadMessages() -> [String] {
        let stored = UserDefaults(suiteName: suiteName)?
            .stringArray(forKey: messagesKey) ?? []
        return stored.isEmpty ? fallback : stored
    }
}

// MARK: - Timeline

struct ComplicationEntry: TimelineEntry {
    let date: Date
    let message: String
}

struct ComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> ComplicationEntry {
        ComplicationEntry(
            date: Date(),
            message: "You are enough."
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ComplicationEntry) -> Void) {
        let pool = WatchCache.loadMessages()
        completion(ComplicationEntry(
            date: Date(),
            message: pool.randomElement() ?? "You are enough."
        ))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ComplicationEntry>) -> Void) {
        let pool = WatchCache.loadMessages()
        let now = Date()

        // 6 entries, one every 30 minutes — gives the complication a 3-hour
        // rotation before WidgetCenter is asked to refresh the timeline.
        // The Watch app calls `WidgetCenter.reloadAllTimelines()` whenever
        // a fresh iPhone push arrives, so this is a fallback cadence only.
        var entries: [ComplicationEntry] = []
        var iterator = pool.shuffled().makeIterator()
        for i in 0..<6 {
            let next = iterator.next() ?? pool.randomElement() ?? "You are enough."
            entries.append(ComplicationEntry(
                date: now.addingTimeInterval(Double(i) * 1800),
                message: next
            ))
        }

        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

// MARK: - Theme tokens (subset, target-local)

private enum CT {
    static let ink = Color(red: 0.161, green: 0.145, blue: 0.141)
    static let brand = Color(red: 0.475, green: 0.314, blue: 0.239)

    static func display(size: CGFloat) -> Font {
        if let _ = UIFont(name: "NotoSerifDisplay-Light", size: size) {
            return .custom("NotoSerifDisplay-Light", size: size)
        }
        return .system(size: size, weight: .light, design: .serif)
    }
}

// MARK: - View

struct ComplicationEntryView: View {
    var entry: ComplicationEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Lumi")
                .font(.system(size: 10, design: .serif))
                .italic()
                .foregroundStyle(CT.brand.opacity(0.75))
                .kerning(0.8)

            Text(entry.message)
                .font(CT.display(size: 13))
                .foregroundStyle(CT.ink)
                .lineLimit(3)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}

// MARK: - Widget

@main
struct LumiWatchComplication: Widget {
    let kind = "LumiWatchComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ComplicationProvider()) { entry in
            ComplicationEntryView(entry: entry)
        }
        .configurationDisplayName("Lumi")
        .description("A gentle message on your watch face.")
        .supportedFamilies([.accessoryRectangular])
    }
}
