import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - 1. MODELS
struct Conversation {
    let id: String
    let otherUserEmail: String
    let otherUserName: String
    let lastMessage: String
    let date: Date
}

struct ChatMessage {
    let id: String?
    let senderId: String
    let text: String
    let sentAt: Date
    
    // Helper to convert to Firestore Data
    var dictionary: [String: Any] {
        return [
            "senderId": senderId,
            "text": text,
            "sentAt": Timestamp(date: sentAt)
        ]
    }
}

// MARK: - 2. REPOSITORY
final class ChatRepository {
    
    static let shared = ChatRepository()
    private let db = Firestore.firestore()
    private init() {}

    // --- CONVERSATIONS ---
    
    func fetchConversations(completion: @escaping (Result<[Conversation], Error>) -> Void) {
        guard let currentUserEmail = Auth.auth().currentUser?.email else { return }

        db.collection("conversations")
            .whereField("participants", arrayContains: currentUserEmail)
            .addSnapshotListener { snapshot, error in
                
                if let error = error { completion(.failure(error)); return }
                guard let documents = snapshot?.documents else { completion(.success([])); return }
                
                var fetchedChats: [Conversation] = []
                let group = DispatchGroup()
                
                for doc in documents {
                    let data = doc.data()
                    let id = doc.documentID
                    let lastMsg = data["lastMessage"] as? String ?? "New Chat"
                    let ts = data["lastMessageTimestamp"] as? Timestamp
                    let date = ts?.dateValue() ?? Date()
                    let participants = data["participants"] as? [String] ?? []
                    
                    if let otherEmail = participants.first(where: { $0 != currentUserEmail }) {
                        group.enter()
                        self.fetchUserName(email: otherEmail) { name in
                            fetchedChats.append(Conversation(id: id, otherUserEmail: otherEmail, otherUserName: name, lastMessage: lastMsg, date: date))
                            group.leave()
                        }
                    }
                }
                
                group.notify(queue: .main) {
                    fetchedChats.sort { $0.date > $1.date }
                    completion(.success(fetchedChats))
                }
            }
    }

    // --- MESSAGES (The missing part!) ---

    func fetchMessages(conversationId: String, completion: @escaping (Result<[ChatMessage], Error>) -> Void) {
        db.collection("conversations").document(conversationId).collection("messages")
            .order(by: "sentAt", descending: false)
            .addSnapshotListener { snapshot, error in
                
                if let error = error { completion(.failure(error)); return }
                
                let messages = snapshot?.documents.compactMap { doc -> ChatMessage? in
                    let data = doc.data()
                    let senderId = data["senderId"] as? String ?? ""
                    let text = data["text"] as? String ?? ""
                    let ts = data["sentAt"] as? Timestamp
                    return ChatMessage(id: doc.documentID, senderId: senderId, text: text, sentAt: ts?.dateValue() ?? Date())
                } ?? []
                
                completion(.success(messages))
            }
    }
    
    func sendMessage(conversationId: String, message: ChatMessage, completion: @escaping (Result<Void, Error>) -> Void) {
        // 1. Add message to subcollection
        db.collection("conversations").document(conversationId).collection("messages").addDocument(data: message.dictionary) { error in
            if let error = error { completion(.failure(error)); return }
            
            // 2. Update parent conversation with last message
            self.db.collection("conversations").document(conversationId).updateData([
                "lastMessage": message.text,
                "lastMessageTimestamp": Timestamp(date: message.sentAt)
            ])
            
            completion(.success(()))
        }
    }

    // --- HELPER ---
    private func fetchUserName(email: String, completion: @escaping (String) -> Void) {
        db.collection("users").whereField("email", isEqualTo: email).getDocuments { snapshot, _ in
            if let doc = snapshot?.documents.first {
                let firstName = doc["firstName"] as? String ?? "User"
                let lastName = doc["lastName"] as? String ?? ""
                completion("\(firstName) \(lastName)")
            } else {
                completion(email)
            }
        }
    }
}
