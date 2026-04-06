import Foundation
import FirebaseFunctions

struct LumiMessage: Identifiable, Codable {
    let id: String
    let text: String
    let mood: String
}

final class CloudFunctionService {
    static let shared = CloudFunctionService()
    private let functions = Functions.functions(region: "europe-west1")

    private init() {}

    // MARK: - Message Feed (for swipe stack)

    func getMessageFeed(mood: String? = nil) async throws -> [LumiMessage] {
        var data: [String: Any] = [:]
        if let mood, mood != "Random" { data["mood"] = mood }

        let result = try await functions.httpsCallable("getMessageFeed").call(data)
        guard let dict = result.data as? [String: Any],
              let success = dict["success"] as? Bool, success,
              let messagesArray = dict["messages"] as? [[String: Any]] else {
            return []
        }

        return messagesArray.compactMap { msg in
            guard let id = msg["id"] as? String,
                  let text = msg["text"] as? String,
                  let mood = msg["mood"] as? String else { return nil }
            return LumiMessage(id: id, text: text, mood: mood)
        }
    }

    // MARK: - Rate Message (swipe)

    func rateMessage(messageId: String, rating: String) async throws {
        let data: [String: Any] = ["messageId": messageId, "rating": rating]
        _ = try await functions.httpsCallable("rateMessage").call(data)
    }

    // MARK: - Save to Vault

    func saveToVault(messageId: String, text: String, mood: String) async throws {
        let data: [String: Any] = ["messageId": messageId, "text": text, "mood": mood]
        _ = try await functions.httpsCallable("saveToVault").call(data)
    }

    // MARK: - Report Message

    func reportMessage(messageId: String, reason: String = "") async throws {
        let data: [String: Any] = ["messageId": messageId, "reason": reason]
        _ = try await functions.httpsCallable("reportMessage").call(data)
    }

    // MARK: - Connection Code

    func generateConnectionCode() async throws -> String {
        let result = try await functions.httpsCallable("generateConnectionCode").call()
        guard let dict = result.data as? [String: Any],
              let code = dict["code"] as? String else { return "" }
        return code
    }

    func checkConnectionCode(friendCode: String) async throws -> (success: Bool, message: String) {
        let data: [String: Any] = ["friendCode": friendCode]
        let result = try await functions.httpsCallable("checkConnectionCode").call(data)
        guard let dict = result.data as? [String: Any] else { return (false, "") }
        return (dict["success"] as? Bool ?? false, dict["message"] as? String ?? "")
    }

    // MARK: - Support

    func submitSupportTicket(issueText: String) async throws {
        let data: [String: Any] = ["issueText": issueText]
        _ = try await functions.httpsCallable("submitSupportTicket").call(data)
    }
}
