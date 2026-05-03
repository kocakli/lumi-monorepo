import SwiftUI

@MainActor
final class SensitiveDaysService: ObservableObject {
    static let shared = SensitiveDaysService()

    @AppStorage("sensitiveDays_enabled") var isEnabled = false
    @AppStorage("sensitiveDays_lastStart") var lastStartTimestamp: Double = 0
    @AppStorage("sensitiveDays_duration") var duration: Int = 5       // 3-10 days
    @AppStorage("sensitiveDays_cycleLength") var cycleLength: Int = 28 // 21-40 days

    private init() {}

    var lastStartDate: Date {
        get { Date(timeIntervalSince1970: lastStartTimestamp) }
        set { lastStartTimestamp = newValue.timeIntervalSince1970 }
    }

    var isConfigured: Bool {
        lastStartTimestamp > 0
    }

    /// Is today within a sensitive period?
    var isSensitiveToday: Bool {
        guard isEnabled, isConfigured else { return false }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let start = calendar.startOfDay(for: lastStartDate)

        guard let daysSinceStart = calendar.dateComponents([.day], from: start, to: today).day,
              daysSinceStart >= 0 else { return false }

        let dayInCycle = daysSinceStart % cycleLength
        return dayInCycle < duration
    }

    /// Next sensitive period start date
    var nextPeriodStart: Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        guard isConfigured else { return today }

        let start = calendar.startOfDay(for: lastStartDate)
        guard let daysSinceStart = calendar.dateComponents([.day], from: start, to: today).day else {
            return today
        }

        let dayInCycle = daysSinceStart % cycleLength

        if dayInCycle < duration {
            // Currently in a sensitive period — return current period start
            let daysIntoPeriod = dayInCycle
            return calendar.date(byAdding: .day, value: -daysIntoPeriod, to: today) ?? today
        }

        // Not in sensitive period — return next cycle start
        let daysUntilNext = cycleLength - dayInCycle
        return calendar.date(byAdding: .day, value: daysUntilNext, to: today) ?? today
    }

    /// Next sensitive period end date
    var nextPeriodEnd: Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: duration - 1, to: nextPeriodStart) ?? nextPeriodStart
    }

    /// Days until next sensitive period (0 if currently in one)
    var daysUntilNextPeriod: Int {
        guard isConfigured else { return 0 }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if isSensitiveToday { return 0 }

        return calendar.dateComponents([.day], from: today, to: nextPeriodStart).day ?? 0
    }
}
