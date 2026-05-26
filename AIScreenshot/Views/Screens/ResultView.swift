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
                Button {
                    showImagePreview = true
                } label: {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 180)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous))
                        .overlay(alignment: .bottomTrailing) {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(8)
                                .background(.black.opacity(0.45))
                                .clipShape(Circle())
                                .padding(10)
                        }
                        .shadow(color: .black.opacity(0.12), radius: 18, y: 8)
                        .contentShape(RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous))
                }
                .buttonStyle(.plain)

                if viewModel.step != .done && viewModel.step != .failed {
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
                    SelectableContentText(
                        text: viewModel.summary,
                        placeholder: "正在等待 AI 总结...",
                        parseMarkdown: true
                    )
                }

                PrimaryButton(title: viewModel.copied ? "已复制" : "复制全部", systemImage: viewModel.copied ? "checkmark" : "doc.on.doc", isSuccess: viewModel.copied) {
                    viewModel.copyAll()
                }
            }
            .padding(20)
        }
        .background(DS.ColorToken.background.ignoresSafeArea())
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
