import Foundation
import Combine

@MainActor
final class ChatStore: ObservableObject {
    @Published private(set) var conversations: [UUID: [ChatMessage]] = [:]

    private let key = "chat_conversations_by_result"

    init() {
        load()
    }

    func messages(for resultID: UUID?) -> [ChatMessage] {
        guard let resultID else { return [] }
        return conversations[resultID] ?? []
    }

    func save(_ messages: [ChatMessage], for resultID: UUID?) {
        guard let resultID else { return }
        conversations[resultID] = messages
        persist()
    }

    func deleteConversation(for resultID: UUID) {
        conversations.removeValue(forKey: resultID)
        persist()
    }

    func clear() {
        conversations.removeAll()
        persist()
    }

    private func persist() {
        let payload = conversations.map { StoredChatConversation(resultID: $0.key, messages: $0.value) }
        if let data = try? JSONEncoder().encode(payload) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let payload = try? JSONDecoder().decode([StoredChatConversation].self, from: data)
        else { return }

        conversations = Dictionary(uniqueKeysWithValues: payload.map { ($0.resultID, $0.messages) })
    }
}

private struct StoredChatConversation: Codable {
    let resultID: UUID
    let messages: [ChatMessage]
}
