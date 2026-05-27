import Foundation

struct ShareAISettings {
    static let appGroupID = "group.com.fun.AIScreenshot"

    let apiKey: String
    let model: String
    let fallbackToLocal: Bool

    static var current: ShareAISettings {
        let defaults = UserDefaults(suiteName: appGroupID) ?? .standard
        return ShareAISettings(
            apiKey: defaults.string(forKey: "openai_api_key") ?? "",
            model: defaults.string(forKey: "openai_model") ?? ShareOpenAIConfig.defaultModel,
            fallbackToLocal: defaults.object(forKey: "fallback_to_local") as? Bool ?? true
        )
    }
}

enum ShareOpenAIConfig {
    static let defaultModel = "gpt-4.1-mini"
    static let responsesURL = URL(string: "https://api.openai.com/v1/responses")!
}
