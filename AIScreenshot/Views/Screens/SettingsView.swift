import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var revealOpenAIKey = false
    @State private var revealDeepSeekKey = false
    @State private var revealQwenKey = false
    @State private var revealKimiKey = false
    @State private var revealXiaomiKey = false
    @State private var revealCustomKey = false

    var body: some View {
        Form {
            Section {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14).fill(DS.ColorToken.primary.opacity(0.12))
                        Image(systemName: "sparkles").foregroundStyle(DS.ColorToken.primary)
                    }
                    .frame(width: 46, height: 46)
                    VStack(alignment: .leading) {
                        Text("AI 截图助手").font(.headline)
                        Text("文字识别 + AI 总结").font(.caption).foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("AI 服务") {
                Picker("服务商", selection: $settings.provider) {
                    ForEach(AIProvider.allCases) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }
            }

            activeProviderSection

            Section("通用") {
                Toggle("AI 失败时使用本地免费模式", isOn: $settings.fallbackToLocal)
                Toggle("自动复制结果", isOn: $settings.autoCopy)
            }

            Section("后续计划") {
                Label("分享扩展", systemImage: "square.and.arrow.up")
                Label("小组件", systemImage: "rectangle.grid.2x2")
                Label("云同步", systemImage: "icloud")
            }
        }
        .navigationTitle("设置")
    }

    @ViewBuilder
    private var activeProviderSection: some View {
        Section(settings.provider.displayName) {
            if settings.provider == .local {
                Label("不需要 API 密钥，使用 OCR 文本生成基础本地总结", systemImage: "checkmark.shield")
            } else {
                if settings.provider == .custom {
                    TextField("接口地址，例如 https://example.com/v1/chat/completions", text: $settings.customBaseURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                }

                apiKeyField(
                    title: "\(settings.provider.displayName) API 密钥",
                    text: apiKeyBinding(for: settings.provider),
                    reveal: revealBinding(for: settings.provider)
                )

                if settings.provider == .custom {
                    TextField("模型名称", text: $settings.customModel)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } else {
                    Picker("模型", selection: modelBinding(for: settings.provider)) {
                        ForEach(settings.provider.modelOptions, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                }

                if let url = docsURL(for: settings.provider) {
                    Link("\(settings.provider.displayName) API 文档", destination: url)
                }
            }
        }
    }

    private func apiKeyField(title: String, text: Binding<String>, reveal: Binding<Bool>) -> some View {
        HStack {
            if reveal.wrappedValue {
                TextField(title, text: text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } else {
                SecureField(title, text: text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            Button { reveal.wrappedValue.toggle() } label: {
                Image(systemName: reveal.wrappedValue ? "eye.slash" : "eye")
            }
        }
    }

    private func apiKeyBinding(for provider: AIProvider) -> Binding<String> {
        switch provider {
        case .local:
            return .constant("")
        case .openAI:
            return $settings.apiKey
        case .deepSeek:
            return $settings.deepSeekAPIKey
        case .qwen:
            return $settings.qwenAPIKey
        case .kimi:
            return $settings.kimiAPIKey
        case .xiaomi:
            return $settings.xiaomiAPIKey
        case .custom:
            return $settings.customAPIKey
        }
    }

    private func modelBinding(for provider: AIProvider) -> Binding<String> {
        switch provider {
        case .local:
            return .constant(AIProvider.local.defaultModel)
        case .openAI:
            return $settings.model
        case .deepSeek:
            return $settings.deepSeekModel
        case .qwen:
            return $settings.qwenModel
        case .kimi:
            return $settings.kimiModel
        case .xiaomi:
            return $settings.xiaomiModel
        case .custom:
            return $settings.customModel
        }
    }

    private func revealBinding(for provider: AIProvider) -> Binding<Bool> {
        switch provider {
        case .local:
            return .constant(false)
        case .openAI:
            return $revealOpenAIKey
        case .deepSeek:
            return $revealDeepSeekKey
        case .qwen:
            return $revealQwenKey
        case .kimi:
            return $revealKimiKey
        case .xiaomi:
            return $revealXiaomiKey
        case .custom:
            return $revealCustomKey
        }
    }

    private func docsURL(for provider: AIProvider) -> URL? {
        switch provider {
        case .local:
            return nil
        case .openAI:
            return URL(string: "https://platform.openai.com/docs")
        case .deepSeek:
            return URL(string: "https://api-docs.deepseek.com")
        case .qwen:
            return URL(string: "https://help.aliyun.com/zh/model-studio")
        case .kimi:
            return URL(string: "https://platform.kimi.ai/docs")
        case .xiaomi:
            return URL(string: "https://openrouter.ai/xiaomi")
        case .custom:
            return nil
        }
    }
}
