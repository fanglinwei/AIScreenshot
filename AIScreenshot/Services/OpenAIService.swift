import Foundation

struct OpenAIService {
    let provider: AIProvider
    let apiKey: String
    let model: String
    let baseURL: String
    let fallbackToLocal: Bool

    func summarize(
        text: String,
        mode: SummaryMode,
        screenshotType: ScreenshotType = .unknown,
        intelligenceContext: ScreenshotIntelligenceContext = .empty
    ) async throws -> String {
        var result = ""
        for try await delta in streamSummary(text: text, mode: mode, screenshotType: screenshotType, intelligenceContext: intelligenceContext) {
            result += delta
        }
        return result.isEmpty ? "AI 没有返回可用总结。" : result
    }

    func streamSummary(
        text: String,
        mode: SummaryMode,
        screenshotType: ScreenshotType = .unknown,
        intelligenceContext: ScreenshotIntelligenceContext = .empty
    ) -> AsyncThrowingStream<String, Error> {
        guard provider != .local, !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return Self.localFallbackSummaryStream(text: text, mode: mode, provider: provider, screenshotType: screenshotType, intelligenceContext: intelligenceContext)
        }

        switch provider {
        case .openAI:
            return streamOpenAI(text: text, mode: mode, screenshotType: screenshotType, intelligenceContext: intelligenceContext)
        case .local:
            return Self.localFallbackSummaryStream(text: text, mode: mode, provider: provider, screenshotType: screenshotType, intelligenceContext: intelligenceContext)
        case .deepSeek, .qwen, .kimi, .xiaomi, .custom:
            return streamChatCompletions(text: text, mode: mode, screenshotType: screenshotType, intelligenceContext: intelligenceContext)
        }
    }

    func streamChat(screenshotType: ScreenshotType, ocrText: String, summary: String, messages: [ChatMessage]) -> AsyncThrowingStream<String, Error> {
        guard provider != .local, !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return Self.localFallbackChatStream(messages: messages, provider: provider)
        }

        switch provider {
        case .openAI:
            return streamOpenAIChat(screenshotType: screenshotType, ocrText: ocrText, summary: summary, messages: messages)
        case .local:
            return Self.localFallbackChatStream(messages: messages, provider: provider)
        case .deepSeek, .qwen, .kimi, .xiaomi, .custom:
            return streamChatCompletionsChat(screenshotType: screenshotType, ocrText: ocrText, summary: summary, messages: messages)
        }
    }

    private func streamOpenAI(
        text: String,
        mode: SummaryMode,
        screenshotType: ScreenshotType,
        intelligenceContext: ScreenshotIntelligenceContext
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    var request = URLRequest(url: OpenAIConfig.responsesURL)
                    request.httpMethod = "POST"
                    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                    let payload: [String: Any] = [
                        "model": model,
                        "stream": true,
                        "input": [
                            ["role": "system", "content": PromptService.summarySystemPrompt(for: mode)],
                            ["role": "user", "content": PromptRouter.prompt(for: screenshotType, ocrText: text, intelligenceContext: intelligenceContext)]
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

    private func streamChatCompletions(
        text: String,
        mode: SummaryMode,
        screenshotType: ScreenshotType,
        intelligenceContext: ScreenshotIntelligenceContext
    ) -> AsyncThrowingStream<String, Error> {
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
                            ["role": "user", "content": PromptRouter.prompt(for: screenshotType, ocrText: text, intelligenceContext: intelligenceContext)]
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

    private func streamOpenAIChat(screenshotType: ScreenshotType, ocrText: String, summary: String, messages: [ChatMessage]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    var request = URLRequest(url: OpenAIConfig.responsesURL)
                    request.httpMethod = "POST"
                    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                    let input = chatPayloadMessages(screenshotType: screenshotType, ocrText: ocrText, summary: summary, messages: messages)
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

    private func streamChatCompletionsChat(screenshotType: ScreenshotType, ocrText: String, summary: String, messages: [ChatMessage]) -> AsyncThrowingStream<String, Error> {
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
                        "messages": chatPayloadMessages(screenshotType: screenshotType, ocrText: ocrText, summary: summary, messages: messages),
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

    private func chatPayloadMessages(screenshotType: ScreenshotType, ocrText: String, summary: String, messages: [ChatMessage]) -> [[String: String]] {
        var payload = [
            ["role": "system", "content": PromptService.chatSystemPrompt()],
            ["role": "user", "content": PromptService.chatContextPrompt(screenshotType: screenshotType, ocrText: ocrText, summary: summary)]
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

        let fallbackType = ScreenshotClassifier.classify(ocrText: text)
        let summary = Self.localFallbackSummary(
            text: text,
            mode: mode,
            provider: provider,
            screenshotType: fallbackType,
            intelligenceContext: ScreenshotIntelligenceService.context(for: fallbackType, ocrText: text)
        )
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
        var attempt = 0

        while true {
            do {
                try await streamOnce(request: request, provider: provider, continuation: continuation)
                return
            } catch is CancellationError {
                throw CancellationError()
            } catch let error as APIError where error.retryable && attempt < OpenAIConfig.maxRetryCount {
                attempt += 1
                try await Task.sleep(nanoseconds: OpenAIConfig.retryDelayNanoseconds(forAttempt: attempt))
            } catch let error as URLError where !Task.isCancelled {
                let apiError = APIError.network(error)
                guard apiError.retryable && attempt < OpenAIConfig.maxRetryCount else {
                    throw apiError
                }
                attempt += 1
                try await Task.sleep(nanoseconds: OpenAIConfig.retryDelayNanoseconds(forAttempt: attempt))
            } catch {
                throw error
            }
        }
    }

    private func streamOnce(
        request: URLRequest,
        provider: AIProvider,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        let (bytes, response) = try await URLSession.shared.bytes(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.badResponse("AI 服务没有返回有效响应。")
        }

        guard (200..<300).contains(http.statusCode) else {
            let message = await errorMessage(from: bytes) ?? statusMessage(for: http.statusCode)
            throw APIError.from(statusCode: http.statusCode, message: message)
        }

        do {
            for try await line in bytes.lines {
                try Task.checkCancellation()
                if let delta = try SSEParser.textDelta(from: line, provider: provider), !delta.isEmpty {
                    continuation.yield(delta)
                }
            }
        } catch let error as URLError {
            throw APIError.network(error)
        }

        continuation.finish()
    }

    private func errorMessage(from bytes: URLSession.AsyncBytes) async -> String? {
        do {
            var lines: [String] = []
            for try await line in bytes.lines {
                lines.append(line)
                if lines.count >= 16 { break }
            }

            let body = lines.joined(separator: "\n")
            guard !body.isEmpty else { return nil }
            let data = Data(body.utf8)
            guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return body
            }

            if let error = object["error"] as? [String: Any],
               let message = error["message"] as? String {
                return message
            }

            return object["message"] as? String ?? body
        } catch {
            return nil
        }
    }

    static func localFallbackSummary(
        text: String,
        mode: SummaryMode,
        provider: AIProvider,
        screenshotType: ScreenshotType = .unknown,
        intelligenceContext: ScreenshotIntelligenceContext = .empty
    ) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "未识别到可总结的文字。" }
        let preview = String(trimmed.prefix(120))
        return """
        \(ResultInsight.Section.summary.markdownHeading)
        已识别这是一张\(screenshotType.displayName)截图，当前使用本地模式生成基础理解。

        \(ResultInsight.Section.intent.markdownHeading)
        \(intelligenceContext.suspectedIntent)

        \(ResultInsight.Section.visualUnderstanding.markdownHeading)
        \(intelligenceContext.visualUnderstanding)

        \(ResultInsight.Section.keyPoints.markdownHeading)
        - 重点内容开头：\(preview)\(trimmed.count > 120 ? "..." : "")

        \(ResultInsight.Section.actions.markdownHeading)
        - 配置 \(provider.displayName) API 密钥后可获得更完整的截图智能理解。

        \(ResultInsight.Section.explanation.markdownHeading)
        本地模式主要基于 OCR、截图类型和规则推断，无法进行深度语义推理。

        \(ResultInsight.Section.risks.markdownHeading)
        - 信息可能不完整，请结合原截图确认。

        \(ResultInsight.Section.relatedQuestions.markdownHeading)
        - 这张截图最需要我帮你解释、回复、调试还是提取待办？
        """
    }

    static func localFallbackSummaryStream(
        text: String,
        mode: SummaryMode,
        provider: AIProvider,
        screenshotType: ScreenshotType = .unknown,
        intelligenceContext: ScreenshotIntelligenceContext = .empty
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                let summary = localFallbackSummary(
                    text: text,
                    mode: mode,
                    provider: provider,
                    screenshotType: screenshotType,
                    intelligenceContext: intelligenceContext
                )
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

    enum APIError: LocalizedError, Equatable {
        case network(URLError)
        case rateLimit
        case tokenLimit
        case server(statusCode: Int, message: String)
        case unauthorized
        case badResponse(String)

        var retryable: Bool {
            switch self {
            case .network, .rateLimit, .server:
                return true
            case .tokenLimit, .unauthorized, .badResponse:
                return false
            }
        }

        static func from(statusCode: Int, message: String) -> APIError {
            switch statusCode {
            case 401, 403:
                return .unauthorized
            case 408, 429:
                return .rateLimit
            case 400 where isTokenLimitMessage(message),
                 413 where isTokenLimitMessage(message):
                return .tokenLimit
            case 500..<600:
                return .server(statusCode: statusCode, message: message)
            default:
                if isTokenLimitMessage(message) {
                    return .tokenLimit
                }
                return .badResponse(message)
            }
        }

        var errorDescription: String? {
            switch self {
            case .network:
                return "网络连接失败，请检查网络后重试。"
            case .rateLimit:
                return "请求过于频繁，请稍后再试。"
            case .tokenLimit:
                return "截图内容过长，超过模型可处理的 token 限制。请裁剪截图或减少文本后重试。"
            case .server:
                return "AI 服务暂时不可用，请稍后重试。"
            case .unauthorized:
                return "API 密钥无效，请在设置中检查后重试。"
            case .badResponse(let message):
                return message
            }
        }

        private static func isTokenLimitMessage(_ message: String) -> Bool {
            let lowercased = message.lowercased()
            return lowercased.contains("token") ||
            lowercased.contains("context length") ||
            lowercased.contains("maximum context") ||
            lowercased.contains("too long")
        }
    }
}
