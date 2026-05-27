import Foundation

enum OpenAIConfig {
    static let defaultModel = "gpt-4.1-mini"
    static let responsesURL = URL(string: "https://api.openai.com/v1/responses")!
    static let maxRetryCount = 2

    static func retryDelayNanoseconds(forAttempt attempt: Int) -> UInt64 {
        UInt64(max(1, attempt)) * 650_000_000
    }
}
