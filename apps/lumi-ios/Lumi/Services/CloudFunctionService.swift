import Foundation
import FirebaseAuth

struct LumiMessage: Identifiable, Codable {
    let id: String
    let text: String
    let mood: String
    var isPairMessage: Bool = false
    var isFromPair: Bool = false
    var senderName: String = ""
}

struct PairRequest: Identifiable {
    let id: String
    let fromUserId: String
    let toUserId: String
    let fromUserCode: String
    let status: String
}

struct InAppPairMessage: Identifiable {
    let id: String
    let text: String
    let mood: String
    let senderId: String
}

struct PairedUser: Identifiable {
    let id: String           // connectionId
    let partnerUid: String
    let nickname: String?
}

enum CloudFunctionError: Error {
    case notAuthenticated
    case invalidURL
    case invalidResponse
    case httpError(Int, String)
    case decodingError
}

/// Pure URLSession-based Cloud Functions caller.
///
/// Why not Firebase Functions iOS SDK?
/// The SDK's HTTPSCallable.call(_:) (both async/await AND completion-handler APIs)
/// uses `async let` internally. In Release builds (TestFlight), Swift's concurrency
/// optimizer breaks the async let stack discipline → crashes with
/// `swift_task_dealloc_specific` → `swift_Concurrency_fatalError`. This affects iOS 26.4
/// + Firebase 11.15.x. Bypassing the SDK and calling Cloud Functions directly via the
/// HTTPS endpoint avoids all of this.
///
/// Cloud Functions v2 onCall functions are exposed at:
///   https://<region>-<project>.cloudfunctions.net/<functionName>
/// They expect: POST, Authorization: Bearer <Firebase Auth ID token>, body {"data": ...}
/// They return: {"result": ...}
final class CloudFunctionService {
    static let shared = CloudFunctionService()

    private let baseURL = "https://europe-west1-lumi-tease.cloudfunctions.net"
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    // MARK: - Core Caller

    private func call(_ name: String, data: [String: Any]? = nil) async throws -> [String: Any] {
        // Get Firebase Auth ID token
        guard let user = Auth.auth().currentUser else {
            throw CloudFunctionError.notAuthenticated
        }
        let token = try await user.getIDToken()

        // Build URL
        guard let url = URL(string: "\(baseURL)/\(name)") else {
            throw CloudFunctionError.invalidURL
        }

        // Build request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        // Body wraps payload in {"data": ...}
        let payload: [String: Any] = ["data": data ?? [:]]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        // Send
        let (responseData, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CloudFunctionError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: responseData, encoding: .utf8) ?? ""
            throw CloudFunctionError.httpError(httpResponse.statusCode, body)
        }

        // Parse {"result": ...}
        guard let json = try JSONSerialization.jsonObject(with: responseData) as? [String: Any] else {
            throw CloudFunctionError.decodingError
        }

        if let result = json["result"] as? [String: Any] {
            return result
        }
        return [:]
    }

    // MARK: - Message Feed (for swipe stack)

    func getMessageFeed(mood: String? = nil) async throws -> [LumiMessage] {
        var data: [String: Any] = [:]
        if let mood, mood != "Random" { data["mood"] = mood }

        let dict = try await call("getMessageFeed", data: data)
        guard let success = dict["success"] as? Bool, success,
              let messagesArray = dict["messages"] as? [[String: Any]] else {
            return []
        }

        return messagesArray.compactMap { msg in
            guard let id = msg["id"] as? String,
                  let text = msg["text"] as? String,
                  let mood = msg["mood"] as? String else { return nil }
            return LumiMessage(
                id: id, text: text, mood: mood,
                isPairMessage: msg["isPairMessage"] as? Bool ?? false,
                isFromPair: msg["isFromPair"] as? Bool ?? false,
                senderName: msg["senderName"] as? String ?? ""
            )
        }
    }

    // MARK: - Rate Message (swipe)

    func rateMessage(messageId: String, rating: String) async throws {
        _ = try await call("rateMessage", data: ["messageId": messageId, "rating": rating])
    }

    // MARK: - Save to Vault

    func saveToVault(messageId: String, text: String, mood: String) async throws {
        _ = try await call("saveToVault", data: ["messageId": messageId, "text": text, "mood": mood])
    }

    // MARK: - Report Message

    func reportMessage(messageId: String, reason: String = "") async throws {
        _ = try await call("reportMessage", data: ["messageId": messageId, "reason": reason])
    }

    // MARK: - Connection Code

    func generateConnectionCode() async throws -> String {
        let dict = try await call("generateConnectionCode")
        return (dict["code"] as? String) ?? ""
    }

    func checkConnectionCode(friendCode: String) async throws -> (success: Bool, message: String) {
        let dict = try await call("checkConnectionCode", data: ["friendCode": friendCode])
        return (dict["success"] as? Bool ?? false, dict["message"] as? String ?? "")
    }

    // MARK: - Support

    func submitSupportTicket(issueText: String) async throws {
        _ = try await call("submitSupportTicket", data: ["issueText": issueText])
    }

    // MARK: - Pairing

    func sendPairRequest(friendCode: String) async throws -> (success: Bool, message: String, autoMatched: Bool, connectionId: String?) {
        let dict = try await call("sendPairRequest", data: ["friendCode": friendCode])
        return (
            dict["success"] as? Bool ?? false,
            dict["message"] as? String ?? "",
            dict["autoMatched"] as? Bool ?? false,
            dict["connectionId"] as? String
        )
    }

    func respondToPairRequest(requestId: String, response: String) async throws -> (success: Bool, connectionId: String?) {
        let dict = try await call("respondToPairRequest", data: ["requestId": requestId, "response": response])
        return (dict["success"] as? Bool ?? false, dict["connectionId"] as? String)
    }

    func dissolvePair(connectionId: String) async throws -> Bool {
        let dict = try await call("dissolvePair", data: ["connectionId": connectionId])
        return dict["success"] as? Bool ?? false
    }

    func getPairRequests() async throws -> (incoming: [PairRequest], outgoing: [PairRequest]) {
        let dict = try await call("getPairRequests")

        func parseRequests(_ key: String) -> [PairRequest] {
            guard let arr = dict[key] as? [[String: Any]] else { return [] }
            return arr.compactMap { req in
                guard let id = req["id"] as? String,
                      let from = req["fromUserId"] as? String,
                      let to = req["toUserId"] as? String,
                      let status = req["status"] as? String else { return nil }
                let code = (req["fromUserCode"] as? String) ?? (req["toUserCode"] as? String) ?? ""
                return PairRequest(id: id, fromUserId: from, toUserId: to, fromUserCode: code, status: status)
            }
        }

        return (parseRequests("incoming"), parseRequests("outgoing"))
    }

    func getMyPairs() async throws -> [PairedUser] {
        let dict = try await call("getMyPairs")
        guard let pairsArr = dict["pairs"] as? [[String: Any]] else { return [] }
        return pairsArr.compactMap { p in
            guard let connId = p["connectionId"] as? String,
                  let partnerUid = p["partnerUid"] as? String else { return nil }
            return PairedUser(id: connId, partnerUid: partnerUid, nickname: p["nickname"] as? String)
        }
    }

    func sendPairMessage(text: String, mood: String, targetUserId: String) async throws -> (success: Bool, message: String) {
        let dict = try await call("sendPairMessage", data: ["text": text, "mood": mood, "targetUserId": targetUserId])
        return (dict["success"] as? Bool ?? false, dict["message"] as? String ?? "")
    }

    func updatePairNickname(connectionId: String, nickname: String) async throws -> Bool {
        let dict = try await call("updatePairNickname", data: ["connectionId": connectionId, "nickname": nickname])
        return dict["success"] as? Bool ?? false
    }

    // MARK: - Account Deactivation

    /// Deletes all personal data and the auth user on the backend.
    /// After this call the current ID token is invalid — caller must
    /// sign out locally and re-authenticate to continue using the app.
    func deleteAccount() async throws {
        _ = try await call("deleteAccount")
    }
}
