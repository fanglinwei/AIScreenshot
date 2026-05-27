import Foundation
import Combine

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText = ""
    @Published var isStreaming = false
    @Published var errorMessage: String?

    private var loadedResultID: UUID?

    func suggestions(for screenshotType: ScreenshotType) -> [String] {
        ChatSuggestionProvider.suggestions(for: screenshotType)
    }

    func load(resultID: UUID?, chatStore: ChatStore) {
        guard loadedResultID != resultID else { return }
        loadedResultID = resultID
        messages = chatStore.messages(for: resultID)
        errorMessage = nil
    }

    func send(_ text: String? = nil, screenshotType: ScreenshotType, ocrText: String, summary: String, settings: AppSettings, resultID: UUID?, chatStore: ChatStore) async {
        let question = (text ?? inputText).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty, !isStreaming else { return }

        inputText = ""
        errorMessage = nil

        messages.append(ChatMessage(role: .user, content: question))
        messages.append(ChatMessage(role: .assistant, content: ""))
        let assistantIndex = messages.count - 1
        chatStore.save(messages, for: resultID)
        isStreaming = true

        do {
            let service = OpenAIService(
                provider: settings.provider,
                apiKey: settings.activeAPIKey,
                model: settings.activeModel,
                baseURL: settings.activeBaseURL,
                fallbackToLocal: settings.fallbackToLocal
            )
            let contextMessages = Array(messages.dropLast())
            for try await delta in service.streamChat(screenshotType: screenshotType, ocrText: ocrText, summary: summary, messages: contextMessages) {
                try Task.checkCancellation()
                messages[assistantIndex].content += delta
            }
            isStreaming = false
            chatStore.save(messages, for: resultID)
        } catch is CancellationError {
            isStreaming = false
            chatStore.save(messages, for: resultID)
        } catch {
            isStreaming = false
            errorMessage = error.localizedDescription
            if messages.indices.contains(assistantIndex), messages[assistantIndex].content.isEmpty {
                messages[assistantIndex].content = "回复失败，请稍后重试。"
            }
            chatStore.save(messages, for: resultID)
        }
    }
}
