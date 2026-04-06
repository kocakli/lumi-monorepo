import SwiftUI

@MainActor
final class MessageFeedViewModel: ObservableObject {
    @Published var messages: [LumiMessage] = []
    @Published var currentIndex = 0
    @Published var isLoading = false
    @Published var error: String?
    @Published var savedMessageIds: Set<String> = []

    private let service = CloudFunctionService.shared

    var currentMessage: LumiMessage? {
        currentIndex < messages.count ? messages[currentIndex] : nil
    }

    var hasMessages: Bool { currentMessage != nil }

    func loadFeed(mood: String? = nil) async {
        isLoading = true
        error = nil
        do {
            // Sensitive days: default to Peaceful mood for gentler messages
            let effectiveMood = SensitiveDaysService.shared.isSensitiveToday ? (mood ?? "Peaceful") : mood
            let feed = try await service.getMessageFeed(mood: effectiveMood)
            messages = feed
            currentIndex = 0
            // Share messages with widget
            WidgetDataService.saveMessages(feed.map(\.text))
            // Mark first message received (notification popup triggers after first swipe)
            if !feed.isEmpty && !UserDefaults.standard.bool(forKey: "hasReceivedFirstMessage") {
                UserDefaults.standard.set(true, forKey: "hasReceivedFirstMessage")
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func swipeRight() async {
        guard let msg = currentMessage else { return }
        do {
            try await service.rateMessage(messageId: msg.id, rating: "positive")
        } catch {
            print("Rate error: \(error)")
        }
        advanceToNext()
    }

    func swipeLeft() async {
        guard let msg = currentMessage else { return }
        do {
            try await service.rateMessage(messageId: msg.id, rating: "negative")
        } catch {
            print("Rate error: \(error)")
        }
        advanceToNext()
    }

    func saveCurrentMessage() async {
        guard let msg = currentMessage else { return }
        if savedMessageIds.contains(msg.id) {
            savedMessageIds.remove(msg.id)
            return
        }
        savedMessageIds.insert(msg.id)
        do {
            try await service.saveToVault(messageId: msg.id, text: msg.text, mood: msg.mood)
        } catch {
            savedMessageIds.remove(msg.id)
            print("Save error: \(error)")
        }
    }

    @Published var showReportConfirmation = false

    func reportCurrentMessage() async {
        guard let msg = currentMessage else { return }
        do {
            try await service.reportMessage(messageId: msg.id)
            showReportConfirmation = true
            advanceToNext()
            // Auto-dismiss confirmation after 2 seconds
            try? await Task.sleep(for: .seconds(2))
            showReportConfirmation = false
        } catch {
            print("Report error: \(error)")
        }
    }

    private func advanceToNext() {
        currentIndex += 1
        // Prefetch more when running low
        if currentIndex >= messages.count - 2 {
            Task { await loadMore() }
        }
        // After first swipe, show notification permission (avoids onboarding clash)
        if currentIndex == 1 && UserDefaults.standard.bool(forKey: "hasReceivedFirstMessage") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                NotificationService.shared.checkShouldShowPrePermission()
            }
        }
    }

    private func loadMore() async {
        do {
            let more = try await service.getMessageFeed()
            messages.append(contentsOf: more)
        } catch {
            print("Load more error: \(error)")
        }
    }
}
