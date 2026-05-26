import SwiftUI
import WidgetKit

struct AIScreenshotWidgetEntry: TimelineEntry {
    let date: Date
    let item: WidgetSnapshotItem?
}

struct AIScreenshotWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> AIScreenshotWidgetEntry {
        AIScreenshotWidgetEntry(
            date: Date(),
            item: WidgetSnapshotItem(
                id: UUID(),
                createdAt: Date(),
                title: "会议截图重点",
                summary: "3 个关键结论、2 个待办事项已整理完成。",
                mode: "摘要"
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (AIScreenshotWidgetEntry) -> Void) {
        completion(AIScreenshotWidgetEntry(date: Date(), item: WidgetSnapshotStore.load().first))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AIScreenshotWidgetEntry>) -> Void) {
        let entry = AIScreenshotWidgetEntry(date: Date(), item: WidgetSnapshotStore.load().first)
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}

struct AIScreenshotWidgetView: View {
    let entry: AIScreenshotWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .foregroundStyle(.white)
                Text("AI 截图助手")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.92))
                Spacer(minLength: 0)
            }

            Spacer(minLength: 0)

            if let item = entry.item {
                Text(item.title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text(item.summary)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.82))
                    .lineLimit(3)

                Text(item.mode)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.16))
                    .clipShape(Capsule())
            } else {
                Text("还没有截图记录")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)

                Text("打开 App 上传截图，Widget 会显示最近的 AI 摘要。")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.82))
                    .lineLimit(3)
            }
        }
        .padding(14)
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [
                    Color(red: 0.22, green: 0.36, blue: 0.88),
                    Color(red: 0.02, green: 0.48, blue: 0.56)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .widgetURL(URL(string: "aiscreenshot://import"))
    }
}

struct AIScreenshotWidget: Widget {
    let kind = "AIScreenshotWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AIScreenshotWidgetProvider()) { entry in
            AIScreenshotWidgetView(entry: entry)
        }
        .configurationDisplayName("AI 截图助手")
        .description("快速查看最近一次截图识别和 AI 总结。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct AIScreenshotWidgetBundle: WidgetBundle {
    var body: some Widget {
        AIScreenshotWidget()
    }
}
