import Foundation

struct SSEParser {
    static func textDelta(from line: String, provider: AIProvider) throws -> String? {
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
            let message = error["message"] as? String ?? "AI 服务返回异常，请稍后重试。"
            throw OpenAIService.APIError.badResponse(message)
        }

        switch provider {
        case .openAI:
            return openAITextDelta(from: object)
        case .deepSeek:
            return chatCompletionsTextDelta(from: object)
        }
    }

    private static func openAITextDelta(from object: [String: Any]) -> String? {
        if object["type"] as? String == "response.output_text.delta" {
            return object["delta"] as? String
        }

        if let delta = object["delta"] as? String {
            return delta
        }

        return nil
    }

    private static func chatCompletionsTextDelta(from object: [String: Any]) -> String? {
        guard let choices = object["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let delta = firstChoice["delta"] as? [String: Any] else {
            return nil
        }

        return delta["content"] as? String
    }
}
