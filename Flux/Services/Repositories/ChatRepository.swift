import Foundation
import FirebaseFirestore

final class ChatRepository {
    static let shared = ChatRepository()
    private let manager = FirestoreManager.shared

    private init() {}

    private var conversationsCollection: CollectionReference {
        manager.db.collection("conversations")
    }

    private func messagesCollection(conversationId: String) -> CollectionReference {
        conversationsCollection.document(conversationId).collection("messages")
    }

    // MARK: - Conversation Helpers

    func createOrFetchConversation(
        seekerId: String,
        providerId: String,
        completion: @escaping (Result<Conversation, Error>) -> Void
    ) {
        conversationsCollection.whereField("seekerId", isEqualTo: seekerId)
            .whereField("providerId", isEqualTo: providerId)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let snapshot = snapshot else {
                    completion(.failure(self.manager.missingSnapshotError()))
                    return
                }

                if let document = snapshot.documents.first {
                    do {
                        let conversation = try document.data(as: Conversation.self)
                        completion(.success(conversation))
                    } catch {
                        completion(.failure(error))
                    }
                    return
                }

                let conversation = Conversation(
                    id: nil,
                    participantIds: [seekerId, providerId],
                    seekerId: seekerId,
                    providerId: providerId,
                    serviceId: nil,
                    bookingId: nil,
                    lastMessageText: nil,
                    lastMessageSenderId: nil,
                    lastMessageAt: nil,
                    unreadCount: [seekerId: 0, providerId: 0],
                    createdAt: Date(),
                    updatedAt: Date()
                )

                let document = self.conversationsCollection.document()
                do {
                    try document.setData(from: conversation) { error in
                        if let error = error {
                            completion(.failure(error))
                            return
                        }

                        var createdConversation = conversation
                        createdConversation.id = document.documentID
                        completion(.success(createdConversation))
                    }
                } catch {
                    completion(.failure(error))
                }
            }
    }

    func fetchConversations(
        for userId: String,
        completion: @escaping (Result<[Conversation], Error>) -> Void
    ) {
        conversationsCollection.whereField("participantIds", arrayContains: userId)
            .order(by: "lastMessageAt", descending: true)
            .getDocuments { snapshot, error in
                self.manager.decodeDocuments(snapshot, error: error, completion: completion)
            }
    }

    func updateConversationLastMessage(
        conversationId: String,
        lastMessageText: String?,
        lastMessageSenderId: String,
        lastMessageAt: Date,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let lastMessageValue: Any = lastMessageText ?? NSNull()
        let updates: [String: Any] = [
            "lastMessageText": lastMessageValue,
            "lastMessageSenderId": lastMessageSenderId,
            "lastMessageAt": lastMessageAt,
            "updatedAt": lastMessageAt,
        ]

        conversationsCollection.document(conversationId).updateData(updates) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(()))
        }
    }

    func incrementUnreadCount(
        conversationId: String,
        receiverId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let updates: [String: Any] = [
            "unreadCount.\(receiverId)": FieldValue.increment(Int64(1)),
        ]

        conversationsCollection.document(conversationId).updateData(updates) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(()))
        }
    }

    func resetUnreadCount(
        conversationId: String,
        userId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let updates: [String: Any] = [
            "unreadCount.\(userId)": 0,
        ]

        conversationsCollection.document(conversationId).updateData(updates) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(()))
        }
    }

    // MARK: - Message Helpers

    func sendMessage(
        _ message: ChatMessage,
        completion: @escaping (Result<ChatMessage, Error>) -> Void
    ) {
        let document = messagesCollection(conversationId: message.conversationId).document()
        do {
            try document.setData(from: message) { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                var createdMessage = message
                createdMessage.id = document.documentID
                completion(.success(createdMessage))
            }
        } catch {
            completion(.failure(error))
        }
    }

    func fetchMessages(
        conversationId: String,
        limit: Int? = nil,
        startAfter: DocumentSnapshot? = nil,
        completion: @escaping (Result<[ChatMessage], Error>) -> Void
    ) {
        var query: Query = messagesCollection(conversationId: conversationId)
            .order(by: "sentAt", descending: false)

        if let startAfter = startAfter {
            query = query.start(afterDocument: startAfter)
        }

        if let limit = limit {
            query = query.limit(to: limit)
        }

        query.getDocuments { snapshot, error in
            self.manager.decodeDocuments(snapshot, error: error, completion: completion)
        }
    }

    func markMessagesAsRead(
        conversationId: String,
        userId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        messagesCollection(conversationId: conversationId)
            .whereField("receiverId", isEqualTo: userId)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let snapshot = snapshot else {
                    completion(.failure(self.manager.missingSnapshotError()))
                    return
                }

                guard !snapshot.documents.isEmpty else {
                    completion(.success(()))
                    return
                }

                let batch = self.manager.db.batch()
                let readAt = Date()

                snapshot.documents.forEach { document in
                    batch.updateData(["isRead": true, "readAt": readAt], forDocument: document.reference)
                }

                batch.commit { error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    completion(.success(()))
                }
            }
    }
}
