import SwiftUI
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class PairingViewModel: ObservableObject {
    @Published var myCode: String = ""
    @Published var isLoadingCode = false
    @Published var pairs: [PairedUser] = []
    @Published var incomingRequests: [PairRequest] = []
    @Published var outgoingRequests: [PairRequest] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var successMessage: String?
    @Published var pairingSuccess = false
    @Published var friendCode: String = ""
    @Published var inAppRequest: PairRequest?
    @Published var inAppPairMessage: InAppPairMessage?

    private let service = CloudFunctionService.shared
    private var incomingListener: ListenerRegistration?
    private var outgoingListener: ListenerRegistration?
    private var pairMessageListener: ListenerRegistration?
    private var seenAcceptedIds = Set<String>()
    private var seenIncomingIds = Set<String>()
    private var hasInitializedListeners = false
    private var authStateHandle: AuthStateDidChangeListenerHandle?

    // Persisted across launches — pair messages user has already seen as a banner
    private static let seenPairMsgKey = "pair_msgs_seen_v1"
    private var seenMessageIds: Set<String> {
        get { Set(UserDefaults.standard.stringArray(forKey: Self.seenPairMsgKey) ?? []) }
        set { UserDefaults.standard.set(Array(newValue), forKey: Self.seenPairMsgKey) }
    }
    private func markMessageSeen(_ id: String) {
        var s = seenMessageIds
        s.insert(id)
        seenMessageIds = s
    }

    deinit {
        incomingListener?.remove()
        outgoingListener?.remove()
        pairMessageListener?.remove()
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // MARK: - Real-time Listeners

    /// Starts listening once Firebase Auth is ready. Safe to call multiple times.
    func startListening() {
        guard !hasInitializedListeners else { return }

        // If already authenticated, start immediately
        if let uid = Auth.auth().currentUser?.uid {
            attachListeners(uid: uid)
            return
        }

        // Otherwise wait for auth state to be ready
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self, let uid = user?.uid else { return }
            Task { @MainActor [weak self] in
                self?.attachListeners(uid: uid)
            }
        }
    }

    private func attachListeners(uid: String) {
        guard !hasInitializedListeners else { return }
        hasInitializedListeners = true

        let db = Firestore.firestore()

        // Incoming pair requests
        incomingListener = db.collection("pair_requests")
            .whereField("toUserId", isEqualTo: uid)
            .whereField("status", isEqualTo: "pending")
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let snapshot else { return }
                let requests: [PairRequest] = snapshot.documents.compactMap { doc in
                    let data = doc.data()
                    guard let from = data["fromUserId"] as? String,
                          let to = data["toUserId"] as? String,
                          let status = data["status"] as? String else { return nil }
                    let code = (data["fromUserCode"] as? String) ?? ""
                    return PairRequest(id: doc.documentID, fromUserId: from, toUserId: to, fromUserCode: code, status: status)
                }

                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.incomingRequests = requests
                    // Show banner only for genuinely new requests (not history on cold start)
                    for req in requests where !self.seenIncomingIds.contains(req.id) {
                        self.seenIncomingIds.insert(req.id)
                        // Skip the first batch to avoid spamming on app launch
                        if self.hasInitializedListeners {
                            self.inAppRequest = req
                        }
                    }
                }
            }

        // Accepted outgoing requests — only react to NEWLY accepted (skip cold-start history)
        outgoingListener = db.collection("pair_requests")
            .whereField("fromUserId", isEqualTo: uid)
            .whereField("status", isEqualTo: "accepted")
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let snapshot else { return }
                // Use document changes to detect only new "added" events, not initial snapshot
                let newlyAdded = snapshot.documentChanges.filter { $0.type == .added }
                let newIds = newlyAdded.map { $0.document.documentID }

                Task { @MainActor [weak self] in
                    guard let self else { return }
                    var firstSync = false
                    if self.seenAcceptedIds.isEmpty && !newIds.isEmpty {
                        // First sync — record IDs but don't trigger animation
                        firstSync = true
                    }
                    var hadNew = false
                    for id in newIds where !self.seenAcceptedIds.contains(id) {
                        self.seenAcceptedIds.insert(id)
                        if !firstSync { hadNew = true }
                    }
                    if hadNew {
                        self.pairingSuccess = true
                        await self.loadPairs()
                    }
                }
            }

        // Pair messages targeting me — only show banner for messages user has not seen yet
        pairMessageListener = db.collection("messages")
            .whereField("targetUserId", isEqualTo: uid)
            .whereField("status", isEqualTo: "approved")
            .order(by: "approvedAt", descending: true)
            .limit(to: 5)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let snapshot else { return }

                Task { @MainActor [weak self] in
                    guard let self else { return }
                    let alreadySeen = self.seenMessageIds

                    // Walk through latest messages, find first unseen one
                    for doc in snapshot.documents {
                        let docId = doc.documentID
                        if alreadySeen.contains(docId) { continue }
                        // Found new unseen message — show banner once
                        let data = doc.data()
                        self.inAppPairMessage = InAppPairMessage(
                            id: docId,
                            text: data["text"] as? String ?? "",
                            mood: data["mood"] as? String ?? "Peaceful",
                            senderId: data["senderId"] as? String ?? ""
                        )
                        return
                    }
                }
            }
    }

    func dismissInAppRequest() {
        inAppRequest = nil
    }

    func dismissPairMessage() {
        if let id = inAppPairMessage?.id {
            markMessageSeen(id)
        }
        inAppPairMessage = nil
    }

    // MARK: - Data Loading

    func loadMyCode() async {
        guard Auth.auth().currentUser?.uid != nil else { return }
        isLoadingCode = true
        do {
            myCode = try await service.generateConnectionCode()
        } catch {
            // silent fail — don't crash on auth errors
        }
        isLoadingCode = false
    }

    func loadPairs() async {
        guard Auth.auth().currentUser?.uid != nil else { return }
        do {
            pairs = try await service.getMyPairs()
        } catch {
            // silent fail
        }
    }

    func loadRequests() async {
        guard Auth.auth().currentUser?.uid != nil else { return }
        do {
            let result = try await service.getPairRequests()
            incomingRequests = result.incoming
            outgoingRequests = result.outgoing
        } catch {
            // silent fail
        }
    }

    // MARK: - Actions

    func sendRequest() async {
        let code = friendCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else { return }
        guard Auth.auth().currentUser?.uid != nil else {
            error = "Please wait — signing in..."
            return
        }

        isLoading = true
        error = nil
        do {
            let result = try await service.sendPairRequest(friendCode: code)
            if result.success {
                if result.autoMatched {
                    pairingSuccess = true
                    await loadPairs()
                } else {
                    successMessage = "Pair request sent!"
                }
                friendCode = ""
            } else {
                error = result.message
            }
        } catch {
            self.error = "Failed to send request"
        }
        isLoading = false
    }

    func acceptRequest(_ id: String) async {
        isLoading = true
        do {
            let result = try await service.respondToPairRequest(requestId: id, response: "accept")
            if result.success {
                pairingSuccess = true
                incomingRequests.removeAll { $0.id == id }
                inAppRequest = nil
                await loadPairs()
            }
        } catch {
            self.error = "Failed to accept request"
        }
        isLoading = false
    }

    func rejectRequest(_ id: String) async {
        do {
            let result = try await service.respondToPairRequest(requestId: id, response: "reject")
            if result.success {
                incomingRequests.removeAll { $0.id == id }
                if inAppRequest?.id == id { inAppRequest = nil }
            }
        } catch {
            // silent fail
        }
    }

    func unpair(_ connectionId: String) async {
        do {
            let success = try await service.dissolvePair(connectionId: connectionId)
            if success {
                pairs.removeAll { $0.id == connectionId }
            }
        } catch {
            // silent fail
        }
    }

    func setNickname(for connectionId: String, nickname: String) async {
        do {
            let success = try await service.updatePairNickname(connectionId: connectionId, nickname: nickname)
            if success {
                if let idx = pairs.firstIndex(where: { $0.id == connectionId }) {
                    pairs[idx] = PairedUser(id: connectionId, partnerUid: pairs[idx].partnerUid, nickname: nickname)
                }
            }
        } catch {
            // silent fail
        }
    }
}
