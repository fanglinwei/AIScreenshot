import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var historyStore: HistoryStore
    @EnvironmentObject private var chatStore: ChatStore
    @State private var query = ""

    private var filtered: [OCRResult] {
        guard !query.isEmpty else { return historyStore.items }
        return historyStore.items.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.ocrText.localizedCaseInsensitiveContains(query) ||
            $0.summary.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        List {
            ForEach(filtered) { item in
                NavigationLink { HistoryDetailView(item: item) } label: {
                    HStack(spacing: 12) {
                        historyThumbnail(for: item)

                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(item.title).font(.headline).lineLimit(1)
                                Spacer()
                                Text(item.mode.rawValue).font(.caption2).foregroundStyle(DS.ColorToken.primary)
                            }
                            Text(item.summary).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                            Text(item.createdAt, style: .date).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
            .onDelete(perform: delete)
        }
        .searchable(text: $query, prompt: "搜索识别文本或总结")
        .navigationTitle("历史记录")
        .toolbar {
            if !historyStore.items.isEmpty {
                Button("清空") {
                    historyStore.clear()
                    chatStore.clear()
                }
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        let removed = offsets.map { filtered[$0] }
        historyStore.delete(removed)
        removed.forEach { chatStore.deleteConversation(for: $0.id) }
    }

    @ViewBuilder
    private func historyThumbnail(for item: OCRResult) -> some View {
        if let image = historyStore.image(for: item) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 54, height: 54)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous))
        } else {
            Image(systemName: "doc.text.viewfinder")
                .font(.title3)
                .foregroundStyle(DS.ColorToken.primary)
                .frame(width: 54, height: 54)
                .background(DS.ColorToken.primary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous))
        }
    }
}
