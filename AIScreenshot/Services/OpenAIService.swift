import Foundation

struct OpenAIService {
    let provider: AIProvider
    let apiKey: String
    let model: String

    func summarize(text: String, mode: SummaryMode) async throws -> String {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return Self.localFallbackSummary(text: text, mode: mode, provider: provider)
        }

        switch provider {
        case .openAI:
            return try await summarizeWithOpenAI(text: text, mode: mode)
        case .deepSeek:
            return try await summarizeWithDeepSeek(text: text, mode: mode)
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
                ["role": "system", "content": mode.systemPrompt],
                ["role": "user", "content": "OCR 文本如下：\n\n\(text)"]
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
                ["role": "system", "content": mode.systemPrompt],
                ["role": "user", "content": "OCR 文本如下：\n\n\(text)"]
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
