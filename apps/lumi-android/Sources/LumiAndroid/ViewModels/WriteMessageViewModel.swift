import SwiftUI
import Observation
#if os(Android)
import SkipFirebaseFirestore
#else
import FirebaseFirestore
#endif
#if os(Android)
import SkipFirebaseAuth
#else
import FirebaseAuth
#endif

@Observable
@MainActor
final class WriteMessageViewModel {
    var isSending = false
    var error: String?
    var didSend = false

    func sendMessage(text: String, mood: String, targetUserId: String? = nil) async {
        if let targetUserId {
            await sendPairMessage(text: text, mood: mood, targetUserId: targetUserId)
            return
        }

        guard let uid = Auth.auth().currentUser?.uid else {
            error = "Not signed in"
            return
        }

        isSending = true
        error = nil

        do {
            let db = Firestore.firestore()
            try await db.collection("messages").addDocument(data: [
                "text": text,
                "senderId": uid,
                "mood": mood,
                "status": "pending",
                "createdAt": FieldValue.serverTimestamp()
            ])
            didSend = true
        } catch {
            self.error = error.localizedDescription
        }
        isSending = false
    }

    private func sendPairMessage(text: String, mood: String, targetUserId: String) async {
        isSending = true
        error = nil
        do {
            let result = try await CloudFunctionService.shared.sendPairMessage(
                text: text, mood: mood, targetUserId: targetUserId
            )
            if result.success {
                didSend = true
            } else {
                error = result.message
            }
        } catch {
            self.error = "Failed to send message"
        }
        isSending = false
    }
}
