import SwiftUI

struct ChatView: View {
    let image: UIImage?
    let resultID: UUID?
    let screenshotType: ScreenshotType
    let ocrText: String
    let summary: String

    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var chatStore: ChatStore
    @StateObject private var viewModel = ChatViewModel()
    @State private var showImagePreview = false
    @State private var isContextExpanded = false
    @FocusState private var isChatInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {
                        contextHeader

                        if viewModel.messages.isEmpty {
                            emptyState
                        } else {
                            ForEach(viewModel.messages) { message in
                                ChatBubble(
                                    message: message,
                                    isStreaming: viewModel.isStreaming && message.id == viewModel.messages.last?.id
                                )
                                .id(message.id)
                            }
                        }

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .cardStyle(radius: DS.Radius.md)
                        }
                    }
                    .padding(16)
                }
                .contentShape(Rectangle())
                .simultaneousGesture(
                    TapGesture().onEnded {
                        isChatInputFocused = false
                    }
                )
                .simultaneousGesture(
                    DragGesture(minimumDistance: 8).onChanged { _ in
                        isChatInputFocused = false
                    }
                )
                .scrollDismissesKeyboard(.immediately)
                .background(DS.ColorToken.background)
                .onChange(of: viewModel.messages) { _, messages in
                    guard let last = messages.last else { return }
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }

            chatInput
        }
        .clearsSelectableTextSelectionOnTap()
        .navigationTitle("继续追问")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showImagePreview) {
            if let image {
                ZoomableImageView(image: image)
            }
        }
        .task {
            viewModel.load(resultID: resultID, chatStore: chatStore)
        }
    }

    private var contextHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let image {
                ImagePreviewThumbnail(image: image, height: 150, showsFullImage: true) {
                    showImagePreview = true
                }
            }

            SectionCard(
                title: "截图上下文",
                systemImage: "doc.text.magnifyingglass",
                trailing: AnyView(contextToggleButton)
            ) {
                if isContextExpanded {
                    AIContentText(text: contextFullText)
                } else {
                    AIContentText(text: contextPreview, lineLimit: 4)
                }
            }
        }
    }

    private var contextPreview: String {
        if !summary.isEmpty {
            return "截图类型：\(screenshotType.displayName)\n\n\(summary)"
        }
        return "截图类型：\(screenshotType.displayName)\n\n暂无 AI 总结，仍可基于识别文本追问。"
    }

    private var contextFullText: String {
        contextPreview
    }

    private var contextToggleButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isContextExpanded.toggle()
            }
        } label: {
            Label(isContextExpanded ? "收起" : "展开", systemImage: isContextExpanded ? "chevron.up" : "chevron.down")
                .font(.caption.weight(.semibold))
        }
        .disabled(summary.isEmpty)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            ThinkingIndicator()
            Text("可以继续问这张截图是什么意思、帮你翻译、提炼重点，或者整理成待办。")
                .font(.subheadline)
                .foregroundStyle(DS.ColorToken.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(radius: DS.Radius.md)
    }

    private var chatInput: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.suggestions(for: screenshotType), id: \.self) { suggestion in
                        SuggestionChip(title: suggestion) {
                            Task {
                                await viewModel.send(suggestion, screenshotType: screenshotType, ocrText: ocrText, summary: summary, settings: settings, resultID: resultID, chatStore: chatStore)
                            }
                        }
                        .disabled(viewModel.isStreaming)
                    }
                }
                .padding(.horizontal, 16)
            }

            HStack(spacing: 10) {
                TextField("问问这张截图...", text: $viewModel.inputText, axis: .vertical)
                    .lineLimit(1...4)
                    .textFieldStyle(.plain)
                    .focused($isChatInputFocused)
                    .foregroundStyle(DS.ColorToken.textPrimary)
                    .tint(DS.ColorToken.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(DS.ColorToken.card)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                            .stroke(DS.ColorToken.border, lineWidth: 1)
                    )

                Button {
                    Task {
                        await viewModel.send(screenshotType: screenshotType, ocrText: ocrText, summary: summary, settings: settings, resultID: resultID, chatStore: chatStore)
                    }
                } label: {
                    Image(systemName: viewModel.isStreaming ? "hourglass" : "paperplane.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 46, height: 46)
                        .background(DS.ColorToken.primary)
                        .clipShape(Circle())
                }
                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isStreaming)
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
}
