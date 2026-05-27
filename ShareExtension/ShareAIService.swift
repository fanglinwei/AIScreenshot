import Foundation

struct ShareAIService {
    let settings: ShareAISettings

    func summarize(ocrText: String) async throws -> String {
        let trimmed = ocrText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return "未识别到可总结的文字。"
        }

        guard !settings.apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return localSummary(for: trimmed)
        }

        do {
            return try await openAISummary(for: trimmed)
        } catch {
            guard settings.fallbackToLocal else { throw error }
            return localSummary(for: trimmed)
        }
    }

    private func openAISummary(for text: String) async throws -> String {
        var request = URLRequest(url: ShareOpenAIConfig.responsesURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(settings.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "model": settings.model.isEmpty ? ShareOpenAIConfig.defaultModel : settings.model,
            "stream": true,
            "input": [
                ["role": "system", "content": "你是 AI Screenshot Assistant。请用简洁中文总结分享进来的截图 OCR 文本。"],
                ["role": "user", "content": """
                请总结下面截图文字，输出 3 个部分：
                \(ShareSummarySection.summary.markdownHeading)
                \(ShareSummarySection.keyPoints.markdownHeading)
                \(ShareSummarySection.actions.markdownHeading)

                OCR:
                \(text)
                """]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (bytes, response) = try await URLSession.shared.bytes(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ShareAIError.badResponse("AI 服务没有返回有效响应。")
        }

        guard (200..<300).contains(http.statusCode) else {
            throw ShareAIError.badResponse(statusMessage(for: http.statusCode))
        }

        var result = ""
        for try await line in bytes.lines {
            try Task.checkCancellation()
            if let delta = try textDelta(from: line) {
                result += delta
            }
        }

        return result.isEmpty ? localSummary(for: text) : result
    }

    private func textDelta(from line: String) throws -> String? {
        guard line.hasPrefix("data:") else { return nil }

        let payload = line
            .dropFirst(5)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !payload.isEmpty, payload != "[DONE]" else { return nil }
        let data = Data(payload.utf8)

        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        if let error = object["error"] as? [String: Any] {
            throw ShareAIError.badResponse(error["message"] as? String ?? "AI 服务返回异常。")
        }

        if object["type"] as? String == "response.output_text.delta" {
            return object["delta"] as? String
        }

        return object["delta"] as? String
    }

    private func localSummary(for text: String) -> String {
        let preview = String(text.prefix(180))
        return """
        \(ShareSummarySection.summary.markdownHeading)
        已从分享扩展导入截图，并完成本地 OCR 识别。

        \(ShareSummarySection.keyPoints.markdownHeading)
        \(preview)\(text.count > 180 ? "..." : "")

        \(ShareSummarySection.actions.markdownHeading)
        打开 App 后可继续查看、复制、追问或重新生成总结。
        """
    }

    private func statusMessage(for statusCode: Int) -> String {
        switch statusCode {
        case 401, 403:
            return "API 密钥无效，请在 App 设置中检查。"
        case 408, 429:
            return "请求过于频繁，请稍后再试。"
        case 400, 413:
            return "截图文字过长，超过模型可处理范围。"
        case 500..<600:
            return "AI 服务暂时不可用，请稍后重试。"
        default:
            return "AI 服务返回异常（\(statusCode)）。"
        }
    }
}

enum ShareAIError: LocalizedError {
    case badResponse(String)

    var errorDescription: String? {
        switch self {
        case .badResponse(let message): return message
        }
    }
}

private enum ShareSummarySection: String {
    case summary
    case keyPoints
    case actions

    var markdownHeading: String {
        "## \(NSLocalizedString("result.section.\(rawValue)", comment: ""))"
    }
}
