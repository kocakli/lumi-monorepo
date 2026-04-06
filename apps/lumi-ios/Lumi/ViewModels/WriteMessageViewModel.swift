import SwiftUI
import FirebaseFirestore
import FirebaseAuth

@MainActor
final class WriteMessageViewModel: ObservableObject {
    @Published var isSending = false
    @Published var error: String?
    @Published var didSend = false

    func sendMessage(text: String, mood: String) async {
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
}
