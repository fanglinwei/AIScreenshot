import SwiftUI

struct HistoryDetailView: View {
    let item: OCRResult
    @EnvironmentObject private var historyStore: HistoryStore
    @State private var copied = false
    @State private var showImagePreview = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                if let image = historyStore.image(for: item) {
                    ImagePreviewThumbnail(image: image, height: 240, showsFullImage: true) {
                        showImagePreview = true
                    }
                }

                SectionCard(
                    title: "AI 总结",
                    systemImage: "sparkles",
                    trailing: AnyView(CopyButton(text: item.summary))
                ) {
                    SelectableContentText(text: item.summary, parseMarkdown: true)
                }
                SectionCard(
                    title: "识别文本",
                    systemImage: "text.viewfinder",
                    trailing: AnyView(CopyButton(text: item.ocrText))
                ) {
                    SelectableContentText(text: item.ocrText)
                }
                PrimaryButton(title: copied ? "已复制" : "复制全部", systemImage: copied ? "checkmark" : "doc.on.doc", isSuccess: copied) {
                    UIPasteboard.general.string = "识别文本：\n\(item.ocrText)\n\nAI 总结：\n\(item.summary)"
                    copied = true
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 1_200_000_000)
                        copied = false
                    }
                }
            }
            .padding(20)
        }
        .background(DS.ColorToken.background.ignoresSafeArea())
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showImagePreview) {
            if let image = historyStore.image(for: item) {
                ZoomableImageView(image: image)
            }
        }
    }
}
