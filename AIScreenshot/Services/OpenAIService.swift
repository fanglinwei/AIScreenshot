import Foundation

struct OpenAIService {
    let provider: AIProvider
    let apiKey: String
    let model: String

    func summarize(text: String, mode: SummaryMode) async throws -> String {
        var result = ""
        for try await delta in streamSummary(text: text, mode: mode) {
            result += delta
        }
        return result.isEmpty ? "AI 没有返回可用总结。" : result
    }

    func streamSummary(text: String, mode: SummaryMode) -> AsyncThrowingStream<String, Error> {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return Self.localFallbackSummaryStream(text: text, mode: mode, provider: provider)
        }

        switch provider {
        case .openAI:
            return streamOpenAI(text: text, mode: mode)
        case .deepSeek:
            return streamDeepSeek(text: text, mode: mode)
        }
    }

    func streamChat(ocrText: String, summary: String, messages: [ChatMessage]) -> AsyncThrowingStream<String, Error> {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return Self.localFallbackChatStream(messages: messages, provider: provider)
        }

        switch provider {
        case .openAI:
            return streamOpenAIChat(ocrText: ocrText, summary: summary, messages: messages)
        case .deepSeek:
            return streamDeepSeekChat(ocrText: ocrText, summary: summary, messages: messages)
        }
    }

    private func summarizeWithOpenAI(text: String, mode: SummaryMode) async throws -> String {
        let url = URL(string: "https://api.openai.com/v1/responses")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "model": model,
            "input": [
                ["role": "system", "content": PromptService.summarySystemPrompt(for: mode)],
                ["role": "user", "content": PromptService.summaryUserPrompt(ocrText: text)]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw APIError.badResponse(String(data: data, encoding: .utf8) ?? "AI 服务返回异常，请稍后重试。")
        }

        let decoded = try JSONDecoder().decode(ResponsesAPIResult.self, from: data)
        if let output = decoded.output.first,
           let content = output.content.first,
           let text = content.text {
            return text
        }
        return "AI 没有返回可用总结。"
    }

    private func summarizeWithDeepSeek(text: String, mode: SummaryMode) async throws -> String {
        let url = URL(string: "https://api.deepseek.com/chat/completions")!
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
            "stream": false
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw APIError.badResponse(String(data: data, encoding: .utf8) ?? "AI 服务返回异常，请稍后重试。")
        }

        let decoded = try JSONDecoder().decode(ChatCompletionsAPIResult.self, from: data)
        if let content = decoded.choices.first?.message.content, !content.isEmpty {
            return content
        }
        return "AI 没有返回可用总结。"
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
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func streamDeepSeek(text: String, mode: SummaryMode) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let url = URL(string: "https://api.deepseek.com/chat/completions")!
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
                    try await stream(request: request, provider: .deepSeek, continuation: continuation)
                } catch {
                    continuation.finish(throwing: error)
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
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func streamDeepSeekChat(ocrText: String, summary: String, messages: [ChatMessage]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let url = URL(string: "https://api.deepseek.com/chat/completions")!
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
                    try await stream(request: request, provider: .deepSeek, continuation: continuation)
                } catch {
                    continuation.finish(throwing: error)
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

private struct ResponsesAPIResult: Decodable {
    let output: [Output]
    struct Output: Decodable {
        let content: [Content]
    }
    struct Content: Decodable {
        let text: String?
    }
}

private struct ChatCompletionsAPIResult: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: Message
    }

    struct Message: Decodable {
        let content: String
    }
}
