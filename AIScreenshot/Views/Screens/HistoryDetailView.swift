import SwiftUI

struct HistoryDetailView: View {
    let item: OCRResult
    @EnvironmentObject private var historyStore: HistoryStore
    @State private var copied = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                if let image = historyStore.image(for: item) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 240)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous))
                        .shadow(color: .black.opacity(0.12), radius: 18, y: 8)
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
    }
}
