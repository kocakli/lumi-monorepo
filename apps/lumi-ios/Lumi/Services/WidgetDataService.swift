import Foundation
import WidgetKit

enum WidgetDataService {
    private static let suiteName = "group.com.tease.lumi"
    private static let messagesKey = "widget_messages"

    static func saveMessages(_ messages: [String]) {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        defaults.set(messages, forKey: messagesKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func loadMessages() -> [String] {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return [] }
        return defaults.stringArray(forKey: messagesKey) ?? []
    }
}
