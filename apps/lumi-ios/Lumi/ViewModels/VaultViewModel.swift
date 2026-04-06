import SwiftUI
import FirebaseFirestore
import FirebaseAuth

@MainActor
final class VaultViewModel: ObservableObject {
    @Published var moments: [VaultMoment] = []
    @Published var isLoading = false

    private var listener: ListenerRegistration?

    func startListening() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isLoading = true

        listener = Firestore.firestore()
            .collection("users").document(uid)
            .collection("vault")
            .order(by: "savedAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self, let docs = snapshot?.documents else { return }

                self.moments = docs.map { doc in
                    let data = doc.data()
                    let text = data["text"] as? String ?? ""
                    let mood = data["mood"] as? String ?? ""
                    let savedAt = (data["savedAt"] as? Timestamp)?.dateValue()

                    return VaultMoment(
                        id: doc.documentID,
                        date: Self.formatDate(savedAt),
                        quote: text,
                        tags: [mood.uppercased()],
                        imageName: nil
                    )
                }
                self.isLoading = false
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    func delete(momentId: String) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            try await Firestore.firestore()
                .collection("users").document(uid)
                .collection("vault").document(momentId)
                .delete()
        } catch {
            print("Delete error: \(error)")
        }
    }

    private static func formatDate(_ date: Date?) -> String {
        guard let date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        let dateStr = formatter.string(from: date).uppercased()

        let hour = Calendar.current.component(.hour, from: date)
        let period: String
        switch hour {
        case 5..<12: period = "MORNING"
        case 12..<17: period = "AFTERNOON"
        case 17..<21: period = "EVENING"
        default: period = "NIGHT"
        }

        return "\(dateStr) \u{2022} \(period)"
    }
}
