import SwiftUI
import Observation

@Observable
@MainActor
final class SensitiveDaysService {
    static let shared = SensitiveDaysService()

    // Note: @AppStorage is a property wrapper for SwiftUI views; on a model
    // class we read/write UserDefaults manually so the type can opt into
    // @Observable cleanly (Skip Android lacks Combine, on which @AppStorage
    // observation depends).
    @ObservationIgnored private let store = UserDefaults.standard

    var isEnabled: Bool {
        get { store.bool(forKey: "sensitiveDays_enabled") }
        set { store.set(newValue, forKey: "sensitiveDays_enabled") }
    }
    var lastStartTimestamp: Double {
        get { store.double(forKey: "sensitiveDays_lastStart") }
        set { store.set(newValue, forKey: "sensitiveDays_lastStart") }
    }
    var duration: Int {
        get { (store.object(forKey: "sensitiveDays_duration") as? Int) ?? 5 }
        set { store.set(newValue, forKey: "sensitiveDays_duration") }
    }
    var cycleLength: Int {
        get { (store.object(forKey: "sensitiveDays_cycleLength") as? Int) ?? 28 }
        set { store.set(newValue, forKey: "sensitiveDays_cycleLength") }
    }

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
