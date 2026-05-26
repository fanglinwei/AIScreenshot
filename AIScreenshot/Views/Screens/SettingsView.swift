import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var revealOpenAIKey = false
    @State private var revealDeepSeekKey = false

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
                .pickerStyle(.segmented)
            }

            Section("OpenAI") {
                HStack {
                    if revealOpenAIKey {
                        TextField("OpenAI API 密钥", text: $settings.apiKey)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    } else {
                        SecureField("OpenAI API 密钥", text: $settings.apiKey)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    Button { revealOpenAIKey.toggle() } label: {
                        Image(systemName: revealOpenAIKey ? "eye.slash" : "eye")
                    }
                }

                Picker("模型", selection: $settings.model) {
                    Text("gpt-5.5").tag("gpt-5.5")
                    Text("gpt-5.4").tag("gpt-5.4")
                    Text("gpt-5.4-mini").tag("gpt-5.4-mini")
                    Text("gpt-5.4-nano").tag("gpt-5.4-nano")
                    Text("gpt-4.1-mini").tag("gpt-4.1-mini")
                    Text("gpt-4.1").tag("gpt-4.1")
                    Text("gpt-4o-mini").tag("gpt-4o-mini")
                }
            }

            Section("DeepSeek") {
                HStack {
                    if revealDeepSeekKey {
                        TextField("DeepSeek API 密钥", text: $settings.deepSeekAPIKey)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    } else {
                        SecureField("DeepSeek API 密钥", text: $settings.deepSeekAPIKey)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    Button { revealDeepSeekKey.toggle() } label: {
                        Image(systemName: revealDeepSeekKey ? "eye.slash" : "eye")
                    }
                }

                Picker("模型", selection: $settings.deepSeekModel) {
                    Text("deepseek-v4-flash").tag("deepseek-v4-flash")
                    Text("deepseek-v4-pro").tag("deepseek-v4-pro")
                }
            }

            Section("通用") {
                Toggle("自动复制结果", isOn: $settings.autoCopy)
                Link("OpenAI API 文档", destination: URL(string: "https://platform.openai.com/docs")!)
                Link("DeepSeek API 文档", destination: URL(string: "https://api-docs.deepseek.com")!)
            }

            Section("后续计划") {
                Label("分享扩展", systemImage: "square.and.arrow.up")
                Label("小组件", systemImage: "rectangle.grid.2x2")
                Label("云同步", systemImage: "icloud")
            }
        }
        .navigationTitle("设置")
    }
}
