import Foundation

struct OpenAIService {
    let provider: AIProvider
    let apiKey: String
    let model: String
    let baseURL: String
    let fallbackToLocal: Bool

    func summarize(text: String, mode: SummaryMode) async throws -> String {
        var result = ""
        for try await delta in streamSummary(text: text, mode: mode) {
            result += delta
        }
        return result.isEmpty ? "AI 没有返回可用总结。" : result
    }

    func streamSummary(text: String, mode: SummaryMode) -> AsyncThrowingStream<String, Error> {
        guard provider != .local, !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return Self.localFallbackSummaryStream(text: text, mode: mode, provider: provider)
        }

        switch provider {
        case .openAI:
            return streamOpenAI(text: text, mode: mode)
        case .local:
            return Self.localFallbackSummaryStream(text: text, mode: mode, provider: provider)
        case .deepSeek, .qwen, .kimi, .xiaomi, .custom:
            return streamChatCompletions(text: text, mode: mode)
        }
    }

    func streamChat(ocrText: String, summary: String, messages: [ChatMessage]) -> AsyncThrowingStream<String, Error> {
        guard provider != .local, !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return Self.localFallbackChatStream(messages: messages, provider: provider)
        }

        switch provider {
        case .openAI:
            return streamOpenAIChat(ocrText: ocrText, summary: summary, messages: messages)
        case .local:
            return Self.localFallbackChatStream(messages: messages, provider: provider)
        case .deepSeek, .qwen, .kimi, .xiaomi, .custom:
            return streamChatCompletionsChat(ocrText: ocrText, summary: summary, messages: messages)
        }
    }

    private func streamOpenAI(text: String, mode: SummaryMode) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let url = URL(string: "https://api.openai.com/v1/responses")!
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                    let payload: [String: Any] = [
                        "model": model,
                        "stream": true,
                        "input": [
                            ["role": "system", "content": PromptService.summarySystemPrompt(for: mode)],
                            ["role": "user", "content": PromptService.summaryUserPrompt(ocrText: text)]
                        ]
                    ]

                    request.httpBody = try JSONSerialization.data(withJSONObject: payload)
                    try await stream(request: request, provider: .openAI, continuation: continuation)
                } catch {
                    finishSummaryStreamAfterError(error, text: text, mode: mode, continuation: continuation)
                }
            }

            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func streamChatCompletions(text: String, mode: SummaryMode) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    guard let url = URL(string: baseURL), !model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        throw APIError.badResponse("请在设置中填写有效的接口地址和模型名称。")
                    }
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                    let payload: [String: Any] = [
                        "model": model,
                        "messages": [
                            ["role": "system", "content": PromptService.summarySystemPrompt(for: mode)],
                            ["role": "user", "content": PromptService.summaryUserPrompt(ocrText: text)]
                        ],
                        "stream": true
                    ]

                    request.httpBody = try JSONSerialization.data(withJSONObject: payload)
                    try await stream(request: request, provider: provider, continuation: continuation)
                } catch {
                    finishSummaryStreamAfterError(error, text: text, mode: mode, continuation: continuation)
                }
            }

            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func streamOpenAIChat(ocrText: String, summary: String, messages: [ChatMessage]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let url = URL(string: "https://api.openai.com/v1/responses")!
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                    let input = chatPayloadMessages(ocrText: ocrText, summary: summary, messages: messages)
                    let payload: [String: Any] = [
                        "model": model,
                        "stream": true,
                        "input": input
                    ]

                    request.httpBody = try JSONSerialization.data(withJSONObject: payload)
                    try await stream(request: request, provider: .openAI, continuation: continuation)
                } catch {
                    finishChatStreamAfterError(error, messages: messages, continuation: continuation)
                }
            }

            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func streamChatCompletionsChat(ocrText: String, summary: String, messages: [ChatMessage]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    guard let url = URL(string: baseURL), !model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        throw APIError.badResponse("请在设置中填写有效的接口地址和模型名称。")
                    }
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                    let payload: [String: Any] = [
                        "model": model,
                        "messages": chatPayloadMessages(ocrText: ocrText, summary: summary, messages: messages),
                        "stream": true
                    ]

                    request.httpBody = try JSONSerialization.data(withJSONObject: payload)
                    try await stream(request: request, provider: provider, continuation: continuation)
                } catch {
                    finishChatStreamAfterError(error, messages: messages, continuation: continuation)
                }
            }

            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func chatPayloadMessages(ocrText: String, summary: String, messages: [ChatMessage]) -> [[String: String]] {
        var payload = [
            ["role": "system", "content": PromptService.chatSystemPrompt()],
            ["role": "user", "content": PromptService.chatContextPrompt(ocrText: ocrText, summary: summary)]
        ]

        payload.append(contentsOf: messages.suffix(12).map {
            ["role": $0.role.rawValue, "content": $0.content]
        })

        return payload
    }

    private func finishSummaryStreamAfterError(
        _ error: Error,
        text: String,
        mode: SummaryMode,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) {
        guard fallbackToLocal else {
            continuation.finish(throwing: error)
            return
        }

        let summary = Self.localFallbackSummary(text: text, mode: mode, provider: provider)
        continuation.yield("\n\n\(summary)")
        continuation.finish()
    }

    private func finishChatStreamAfterError(
        _ error: Error,
        messages: [ChatMessage],
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) {
        guard fallbackToLocal else {
            continuation.finish(throwing: error)
            return
        }

        let question = messages.last(where: { $0.role == .user })?.content ?? "这个截图是什么意思？"
        continuation.yield("""
        当前 \(provider.displayName) 服务暂时不可用，已切换为本地免费回复。

        你刚才的问题是：\(question)

        本地模式可以保留问题和上下文，但无法像云端模型一样进行深度推理。
        """)
        continuation.finish()
    }

    private func stream(
        request: URLRequest,
        provider: AIProvider,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        let (bytes, response) = try await URLSession.shared.bytes(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.badResponse("AI 服务没有返回有效响应。")
        }

        guard (200..<300).contains(http.statusCode) else {
            throw APIError.badResponse(statusMessage(for: http.statusCode))
        }

        for try await line in bytes.lines {
            try Task.checkCancellation()
            if let delta = try SSEParser.textDelta(from: line, provider: provider), !delta.isEmpty {
                continuation.yield(delta)
            }
        }

        continuation.finish()
    }

    static func localFallbackSummary(text: String, mode: SummaryMode, provider: AIProvider) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "未识别到可总结的文字。" }
        let preview = String(trimmed.prefix(120))
        return """
        • 已识别截图中的主要文字内容。
        • 重点内容开头：\(preview)\(trimmed.count > 120 ? "..." : "")
        • 当前未配置 \(provider.displayName) API 密钥，因此使用本地占位总结。
        """
    }

    static func localFallbackSummaryStream(text: String, mode: SummaryMode, provider: AIProvider) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                let summary = localFallbackSummary(text: text, mode: mode, provider: provider)
                for character in summary {
                    try? await Task.sleep(nanoseconds: 18_000_000)
                    guard !Task.isCancelled else { return }
                    continuation.yield(String(character))
                }
                continuation.finish()
            }

            continuation.onTermination = { _ in task.cancel() }
        }
    }

    static func localFallbackChatStream(messages: [ChatMessage], provider: AIProvider) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                let question = messages.last(where: { $0.role == .user })?.content ?? "这个截图是什么意思？"
                let answer = """
                当前未配置 \(provider.displayName) API 密钥，因此无法进行真实追问。

                你刚才的问题是：\(question)

                配置 API 密钥后，我可以基于截图 OCR、已有总结和上下文继续解释、翻译、改写或整理待办。
                """
                for character in answer {
                    try? await Task.sleep(nanoseconds: 18_000_000)
                    guard !Task.isCancelled else { return }
                    continuation.yield(String(character))
                }
                continuation.finish()
            }

            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func statusMessage(for statusCode: Int) -> String {
        switch statusCode {
        case 401:
            return "API 密钥无效，请在设置中检查后重试。"
        case 408:
            return "请求超时，请稍后重试。"
        case 429:
            return "请求过于频繁，请稍后再试。"
        case 500..<600:
            return "AI 服务暂时不可用，请稍后重试。"
        default:
            return "AI 服务返回异常（\(statusCode)），请稍后重试。"
        }
    }

    enum APIError: LocalizedError {
        case badResponse(String)
        var errorDescription: String? {
            switch self { case .badResponse(let message): return message }
        }
    }
}
