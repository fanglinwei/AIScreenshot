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

                HStack {
                    Label(item.screenshotType.displayName, systemImage: item.screenshotType.systemImage)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DS.ColorToken.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(DS.ColorToken.primary.opacity(0.10))
                        .clipShape(Capsule())
                    Spacer()
                }

                if !item.tags.isEmpty {
                    SectionCard(title: "标签", systemImage: "tag.fill") {
                        Text(item.tags.map { "#\($0)" }.joined(separator: " "))
                            .font(.subheadline)
                            .foregroundStyle(DS.ColorToken.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                SectionCard(
                    title: "AI 总结",
                    systemImage: "sparkles",
                    trailing: AnyView(CopyButton(text: item.summary))
                ) {
                    AIContentText(text: item.summary)
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

                NavigationLink {
                    ChatView(image: historyStore.image(for: item), resultID: item.id, screenshotType: item.screenshotType, ocrText: item.ocrText, summary: item.summary)
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
            }
            .padding(20)
        }
        .background(DS.ColorToken.background.ignoresSafeArea())
        .clearsSelectableTextSelectionOnTap()
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showImagePreview) {
            if let image = historyStore.image(for: item) {
                ZoomableImageView(image: image)
            }
        }
    }
}
