import Foundation
import Combine

enum AIProvider: String, CaseIterable, Identifiable {
    case local = "local"
    case openAI = "openai"
    case deepSeek = "deepseek"
    case qwen = "qwen"
    case kimi = "kimi"
    case xiaomi = "xiaomi"
    case custom = "custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .local: return "本地免费"
        case .openAI: return "OpenAI"
        case .deepSeek: return "DeepSeek"
        case .qwen: return "通义千问"
        case .kimi: return "Kimi"
        case .xiaomi: return "小米 MiMo"
        case .custom: return "自定义"
        }
    }

    var defaultModel: String {
        switch self {
        case .local: return "local-free"
        case .openAI: return "gpt-5.5"
        case .deepSeek: return "deepseek-v4-flash"
        case .qwen: return "qwen-plus"
        case .kimi: return "kimi-k2.6"
        case .xiaomi: return "xiaomi/mimo-v2.5"
        case .custom: return ""
        }
    }

    var modelOptions: [String] {
        switch self {
        case .local:
            return ["local-free"]
        case .openAI:
            return ["gpt-5.5", "gpt-5.4", "gpt-5.4-mini", "gpt-5.4-nano", "gpt-4.1-mini", "gpt-4.1", "gpt-4o-mini"]
        case .deepSeek:
            return ["deepseek-v4-flash", "deepseek-v4-pro"]
        case .qwen:
            return ["qwen-plus", "qwen-turbo", "qwen-max", "qwen3-plus", "qwen3-turbo"]
        case .kimi:
            return ["kimi-k2.6", "moonshot-v1-8k", "moonshot-v1-32k", "moonshot-v1-128k"]
        case .xiaomi:
            return ["xiaomi/mimo-v2.5", "xiaomi/mimo-v2.5-pro"]
        case .custom:
            return []
        }
    }

    var defaultBaseURL: String {
        switch self {
        case .local:
            return ""
        case .openAI:
            return "https://api.openai.com/v1/responses"
        case .deepSeek:
            return "https://api.deepseek.com/chat/completions"
        case .qwen:
            return "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions"
        case .kimi:
            return "https://api.moonshot.ai/v1/chat/completions"
        case .xiaomi:
            return "https://openrouter.ai/api/v1/chat/completions"
        case .custom:
            return ""
        }
    }

    var isOpenAIResponsesAPI: Bool {
        self == .openAI
    }
}

@MainActor
final class AppSettings: ObservableObject {
    @Published var provider: AIProvider {
        didSet { UserDefaults.standard.set(provider.rawValue, forKey: "ai_provider") }
    }
    @Published var apiKey: String {
        didSet { UserDefaults.standard.set(apiKey, forKey: "openai_api_key") }
    }
    @Published var deepSeekAPIKey: String {
        didSet { UserDefaults.standard.set(deepSeekAPIKey, forKey: "deepseek_api_key") }
    }
    @Published var qwenAPIKey: String {
        didSet { UserDefaults.standard.set(qwenAPIKey, forKey: "qwen_api_key") }
    }
    @Published var kimiAPIKey: String {
        didSet { UserDefaults.standard.set(kimiAPIKey, forKey: "kimi_api_key") }
    }
    @Published var xiaomiAPIKey: String {
        didSet { UserDefaults.standard.set(xiaomiAPIKey, forKey: "xiaomi_api_key") }
    }
    @Published var customAPIKey: String {
        didSet { UserDefaults.standard.set(customAPIKey, forKey: "custom_api_key") }
    }
    @Published var customBaseURL: String {
        didSet { UserDefaults.standard.set(customBaseURL, forKey: "custom_base_url") }
    }
    @Published var model: String {
        didSet { UserDefaults.standard.set(model, forKey: "openai_model") }
    }
    @Published var deepSeekModel: String {
        didSet { UserDefaults.standard.set(deepSeekModel, forKey: "deepseek_model") }
    }
    @Published var qwenModel: String {
        didSet { UserDefaults.standard.set(qwenModel, forKey: "qwen_model") }
    }
    @Published var kimiModel: String {
        didSet { UserDefaults.standard.set(kimiModel, forKey: "kimi_model") }
    }
    @Published var xiaomiModel: String {
        didSet { UserDefaults.standard.set(xiaomiModel, forKey: "xiaomi_model") }
    }
    @Published var customModel: String {
        didSet { UserDefaults.standard.set(customModel, forKey: "custom_model") }
    }
    @Published var fallbackToLocal: Bool {
        didSet { UserDefaults.standard.set(fallbackToLocal, forKey: "fallback_to_local") }
    }
    @Published var autoCopy: Bool {
        didSet { UserDefaults.standard.set(autoCopy, forKey: "auto_copy") }
    }

    var activeAPIKey: String {
        switch provider {
        case .local: return ""
        case .openAI: return apiKey
        case .deepSeek: return deepSeekAPIKey
        case .qwen: return qwenAPIKey
        case .kimi: return kimiAPIKey
        case .xiaomi: return xiaomiAPIKey
        case .custom: return customAPIKey
        }
    }

    var activeModel: String {
        switch provider {
        case .local: return AIProvider.local.defaultModel
        case .openAI: return model
        case .deepSeek: return deepSeekModel
        case .qwen: return qwenModel
        case .kimi: return kimiModel
        case .xiaomi: return xiaomiModel
        case .custom: return customModel
        }
    }

    var activeBaseURL: String {
        provider == .custom ? customBaseURL : provider.defaultBaseURL
    }

    var isLocalProvider: Bool {
        provider == .local
    }

    init() {
        let savedProvider = UserDefaults.standard.string(forKey: "ai_provider")
        self.provider = AIProvider(rawValue: savedProvider ?? "") ?? .openAI
        self.apiKey = UserDefaults.standard.string(forKey: "openai_api_key") ?? ""
        self.deepSeekAPIKey = UserDefaults.standard.string(forKey: "deepseek_api_key") ?? ""
        self.qwenAPIKey = UserDefaults.standard.string(forKey: "qwen_api_key") ?? ""
        self.kimiAPIKey = UserDefaults.standard.string(forKey: "kimi_api_key") ?? ""
        self.xiaomiAPIKey = UserDefaults.standard.string(forKey: "xiaomi_api_key") ?? ""
        self.customAPIKey = UserDefaults.standard.string(forKey: "custom_api_key") ?? ""
        self.customBaseURL = UserDefaults.standard.string(forKey: "custom_base_url") ?? ""
        let savedOpenAIModel = UserDefaults.standard.string(forKey: "openai_model")
        switch savedOpenAIModel {
        case "gpt-4.1-mini", nil:
            self.model = AIProvider.openAI.defaultModel
        default:
            self.model = savedOpenAIModel ?? AIProvider.openAI.defaultModel
        }
        let savedDeepSeekModel = UserDefaults.standard.string(forKey: "deepseek_model")
        switch savedDeepSeekModel {
        case "deepseek-chat", "deepseek-reasoner", nil:
            self.deepSeekModel = AIProvider.deepSeek.defaultModel
        default:
            self.deepSeekModel = savedDeepSeekModel ?? AIProvider.deepSeek.defaultModel
        }
        self.qwenModel = UserDefaults.standard.string(forKey: "qwen_model") ?? AIProvider.qwen.defaultModel
        self.kimiModel = UserDefaults.standard.string(forKey: "kimi_model") ?? AIProvider.kimi.defaultModel
        self.xiaomiModel = UserDefaults.standard.string(forKey: "xiaomi_model") ?? AIProvider.xiaomi.defaultModel
        self.customModel = UserDefaults.standard.string(forKey: "custom_model") ?? ""
        self.fallbackToLocal = UserDefaults.standard.object(forKey: "fallback_to_local") as? Bool ?? true
        self.autoCopy = UserDefaults.standard.object(forKey: "auto_copy") as? Bool ?? false
    }
}
