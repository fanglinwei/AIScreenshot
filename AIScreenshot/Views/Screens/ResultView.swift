import SwiftUI

struct ResultView: View {
    let image: UIImage
    let mode: SummaryMode

    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var historyStore: HistoryStore
    @StateObject private var viewModel = ResultViewModel()
    @State private var showImagePreview = false
    @State private var pendingScrollWorkItem: DispatchWorkItem?
    @State private var didScrollToStreamingStart = false
    private let bottomAnchorID = "result-bottom"

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 18) {
                    ImagePreviewThumbnail(image: image) {
                        showImagePreview = true
                    }

                    HStack {
                        ScreenshotTypeChip(type: viewModel.screenshotType)
                        Spacer()
                    }

                    if viewModel.step == .ocr || viewModel.step == .analyzing {
                        ProcessingView(step: viewModel.step)
                            .cardStyle()
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .cardStyle()
                    }

                    SectionCard(
                        title: "识别文本",
                        systemImage: "text.viewfinder",
                        trailing: AnyView(CopyButton(text: viewModel.ocrText))
                    ) {
                        SelectableContentText(
                            text: viewModel.ocrText,
                            placeholder: "正在等待文字识别..."
                        )
                    }

                    functionChips

                    ForEach(visibleInsightSections, id: \.self) { section in
                        insightSection(section)
                    }

                    relatedScreenshotsSection

                    PrimaryButton(title: viewModel.copied ? "已复制" : "复制全部", systemImage: viewModel.copied ? "checkmark" : "doc.on.doc", isSuccess: viewModel.copied) {
                        viewModel.copyAll()
                    }

                    ShareLink(item: viewModel.shareText) {
                        HStack(spacing: 10) {
                            Image(systemName: "square.and.arrow.up")
                            Text("分享结果")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .foregroundStyle(DS.ColorToken.primary)
                        .background(DS.ColorToken.primary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
                    }
                    .disabled(viewModel.summary.isEmpty && viewModel.ocrText.isEmpty)

                    if !viewModel.ocrText.isEmpty || !viewModel.summary.isEmpty {
                        NavigationLink {
                            ChatView(image: image, resultID: viewModel.savedResultID, screenshotType: viewModel.screenshotType, ocrText: viewModel.ocrText, summary: viewModel.summary)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "message.fill")
                                Text("继续追问")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .foregroundStyle(DS.ColorToken.primary)
                            .background(DS.ColorToken.primary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
                        }
                        .disabled(viewModel.isStreamingSummary)
                    }

                    Color.clear
                        .frame(height: 1)
                        .id(bottomAnchorID)
                }
                .padding(20)
            }
            .onChange(of: viewModel.summary) { _, _ in
                scheduleStreamingScroll(proxy)
            }
            .onChange(of: viewModel.step) { _, step in
                if step == .summary {
                    didScrollToStreamingStart = false
                    scrollToBottom(proxy, animated: true)
                }
            }
            .onChange(of: viewModel.isStreamingSummary) { _, isStreaming in
                if !isStreaming {
                    pendingScrollWorkItem?.cancel()
                    pendingScrollWorkItem = nil
                    scrollToBottom(proxy, animated: true)
                }
            }
        }
        .background(DS.ColorToken.background.ignoresSafeArea())
        .clearsSelectableTextSelectionOnTap()
        .navigationTitle("处理结果")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showImagePreview) {
            ZoomableImageView(image: image)
        }
        .task {
            if viewModel.step == .idle {
                await viewModel.process(image: image, mode: mode, settings: settings, historyStore: historyStore)
            }
        }
        .onDisappear {
            pendingScrollWorkItem?.cancel()
            pendingScrollWorkItem = nil
        }
    }

    private var visibleInsightSections: [ResultInsight.Section] {
        let sections = ResultInsight.visibleSections(for: viewModel.screenshotType)
            .filter { viewModel.insight.hasContent(for: $0) }
        if sections.isEmpty && viewModel.isStreamingSummary {
            return [.summary]
        }
        return sections.isEmpty && !viewModel.summary.isEmpty ? [.summary] : sections
    }

    private func scheduleStreamingScroll(_ proxy: ScrollViewProxy) {
        guard viewModel.isStreamingSummary, !viewModel.summary.isEmpty else { return }
        guard !didScrollToStreamingStart else { return }
        didScrollToStreamingStart = true

        pendingScrollWorkItem?.cancel()
        let workItem = DispatchWorkItem {
            scrollToBottom(proxy, animated: true)
            pendingScrollWorkItem = nil
        }
        pendingScrollWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12, execute: workItem)
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy, animated: Bool) {
        if animated {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(bottomAnchorID, anchor: .bottom)
            }
        } else {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                proxy.scrollTo(bottomAnchorID, anchor: .bottom)
            }
        }
    }

    private var functionChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ResultFunctionChip(title: "解释", systemImage: "lightbulb")
                ResultFunctionChip(title: "翻译", systemImage: "character.book.closed")
                ResultFunctionChip(title: "待办事项", systemImage: "checklist")
                ResultFunctionChip(title: "调试", systemImage: "wrench.and.screwdriver")
                ResultFunctionChip(title: "生成闪卡", systemImage: "rectangle.stack")
            }
        }
    }

    private func insightSection(_ section: ResultInsight.Section) -> some View {
        let content = viewModel.insight.content(for: section)
        return SectionCard(
            title: section.title,
            systemImage: section.systemImage,
            trailing: AnyView(CopyButton(text: content))
        ) {
            if section == .summary {
                StreamingSummaryText(
                    text: content,
                    isStreaming: viewModel.isStreamingSummary
                )
            } else {
                AIContentText(
                    text: content,
                    placeholder: "正在生成..."
                )
            }
        }
    }

    @ViewBuilder
    private var relatedScreenshotsSection: some View {
        let related = relatedScreenshots
        if !related.isEmpty {
            SectionCard(
                title: "相关截图",
                systemImage: "rectangle.stack.fill"
            ) {
                VStack(spacing: 10) {
                    ForEach(related) { item in
                        NavigationLink {
                            HistoryDetailView(item: item)
                        } label: {
                            RelatedScreenshotRow(item: item, image: historyStore.image(for: item))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var relatedScreenshots: [OCRResult] {
        guard let current = viewModel.currentMemoryRecord else { return [] }
        return historyStore.related(to: current, limit: 3)
    }
}

private struct ScreenshotTypeChip: View {
    let type: ScreenshotType

    var body: some View {
        Label(type.displayName, systemImage: type.systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(DS.ColorToken.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(DS.ColorToken.primary.opacity(0.10))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(DS.ColorToken.primary.opacity(0.16), lineWidth: 1)
            )
    }
}

private struct ResultFunctionChip: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(DS.ColorToken.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(DS.ColorToken.elevatedCard)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(DS.ColorToken.border, lineWidth: 1)
            )
    }
}

private struct RelatedScreenshotRow: View {
    let item: OCRResult
    let image: UIImage?

    var body: some View {
        HStack(spacing: 12) {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 46, height: 46)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous))
            } else {
                Image(systemName: item.screenshotType.systemImage)
                    .font(.headline)
                    .foregroundStyle(DS.ColorToken.primary)
                    .frame(width: 46, height: 46)
                    .background(DS.ColorToken.primary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DS.ColorToken.textPrimary)
                        .lineLimit(1)
                    Spacer()
                    Text(item.screenshotType.displayName)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(DS.ColorToken.primary)
                }

                Text(item.summary.isEmpty ? item.ocrText : item.summary)
                    .font(.caption)
                    .foregroundStyle(DS.ColorToken.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(10)
        .background(DS.ColorToken.elevatedCard)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
    }
}
