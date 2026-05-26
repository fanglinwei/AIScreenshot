import Foundation
import Combine

enum AIProvider: String, CaseIterable, Identifiable {
    case openAI = "openai"
    case deepSeek = "deepseek"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .openAI: return "OpenAI"
        case .deepSeek: return "DeepSeek"
        }
    }

    var defaultModel: String {
        switch self {
        case .openAI: return "gpt-5.5"
        case .deepSeek: return "deepseek-v4-flash"
        }
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
    @Published var model: String {
        didSet { UserDefaults.standard.set(model, forKey: "openai_model") }
    }
    @Published var deepSeekModel: String {
        didSet { UserDefaults.standard.set(deepSeekModel, forKey: "deepseek_model") }
    }
    @Published var autoCopy: Bool {
        didSet { UserDefaults.standard.set(autoCopy, forKey: "auto_copy") }
    }

    var activeAPIKey: String {
        switch provider {
        case .openAI: return apiKey
        case .deepSeek: return deepSeekAPIKey
        }
    }

    var activeModel: String {
        switch provider {
        case .openAI: return model
        case .deepSeek: return deepSeekModel
        }
    }

    init() {
        let savedProvider = UserDefaults.standard.string(forKey: "ai_provider")
        self.provider = AIProvider(rawValue: savedProvider ?? "") ?? .openAI
        self.apiKey = UserDefaults.standard.string(forKey: "openai_api_key") ?? ""
        self.deepSeekAPIKey = UserDefaults.standard.string(forKey: "deepseek_api_key") ?? ""
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
        self.autoCopy = UserDefaults.standard.object(forKey: "auto_copy") as? Bool ?? false
    }
}
