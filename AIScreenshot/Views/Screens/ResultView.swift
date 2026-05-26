import SwiftUI

struct ResultView: View {
    let image: UIImage
    let mode: SummaryMode

    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var historyStore: HistoryStore
    @StateObject private var viewModel = ResultViewModel()
    @State private var showImagePreview = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                ImagePreviewThumbnail(image: image) {
                    showImagePreview = true
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

                SectionCard(
                    title: "AI 总结",
                    systemImage: "sparkles",
                    trailing: AnyView(CopyButton(text: viewModel.summary))
                ) {
                    StreamingSummaryText(
                        text: viewModel.summary,
                        isStreaming: viewModel.isStreamingSummary
                    )
                }

                PrimaryButton(title: viewModel.copied ? "已复制" : "复制全部", systemImage: viewModel.copied ? "checkmark" : "doc.on.doc", isSuccess: viewModel.copied) {
                    viewModel.copyAll()
                }

                if !viewModel.ocrText.isEmpty || !viewModel.summary.isEmpty {
                    NavigationLink {
                        ChatView(image: image, resultID: viewModel.savedResultID, ocrText: viewModel.ocrText, summary: viewModel.summary)
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
            }
            .padding(20)
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
    }
}
