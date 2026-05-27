import SwiftUI
import WidgetKit

private enum WidgetDeepLink {
    static let quickOCR = URL(string: "aiscreenshot://quick-ocr")!
    static let daily = URL(string: "aiscreenshot://daily-summary")!
    static let recent = URL(string: "aiscreenshot://recent-summary")!
}

struct AIScreenshotWidgetEntry: TimelineEntry {
    let date: Date
    let payload: WidgetSnapshotPayload

    var latestItem: WidgetSnapshotItem? {
        payload.items.first
    }

    var todayItems: [WidgetSnapshotItem] {
        payload.items.filter { Calendar.current.isDateInToday($0.createdAt) }
    }
}

struct AIScreenshotWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> AIScreenshotWidgetEntry {
        AIScreenshotWidgetEntry(date: Date(), payload: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (AIScreenshotWidgetEntry) -> Void) {
        completion(AIScreenshotWidgetEntry(date: Date(), payload: WidgetSnapshotStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AIScreenshotWidgetEntry>) -> Void) {
        let entry = AIScreenshotWidgetEntry(date: Date(), payload: WidgetSnapshotStore.load())
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}

struct QuickOCRWidgetView: View {
    let entry: AIScreenshotWidgetEntry

    var body: some View {
        WidgetGlassContainer(accent: .cyan) {
            VStack(alignment: .leading, spacing: 10) {
                WidgetHeader(title: "Quick OCR", systemImage: "text.viewfinder")

                Spacer(minLength: 0)

                Text("\(entry.payload.totalCount)")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())

                Text("已保存 Summary")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.82))

                if let latest = entry.latestItem {
                    Text(latest.ocrPreview.isEmpty ? latest.title : latest.ocrPreview)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.72))
                        .lineLimit(2)
                } else {
                    Text("点击打开 App，开始识别截图。")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.72))
                        .lineLimit(2)
                }
            }
        }
        .widgetURL(WidgetDeepLink.quickOCR)
    }
}

struct DailySummaryWidgetView: View {
    let entry: AIScreenshotWidgetEntry

    var body: some View {
        WidgetGlassContainer(accent: .purple) {
            VStack(alignment: .leading, spacing: 10) {
                WidgetHeader(title: "Daily Summary", systemImage: "calendar.badge.clock")

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(entry.payload.todayCount)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("今日")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.76))
                }

                VStack(alignment: .leading, spacing: 7) {
                    ForEach(Array(displayItems.prefix(3))) { item in
                        SummaryLine(item: item)
                    }

                    if displayItems.isEmpty {
                        Text("今天还没有截图摘要")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.78))
                            .lineLimit(2)
                    }
                }

                Spacer(minLength: 0)
            }
        }
        .widgetURL(WidgetDeepLink.daily)
    }

    private var displayItems: [WidgetSnapshotItem] {
        entry.todayItems.isEmpty ? Array(entry.payload.items.prefix(3)) : entry.todayItems
    }
}

struct RecentSummaryWidgetView: View {
    let entry: AIScreenshotWidgetEntry

    var body: some View {
        WidgetGlassContainer(accent: .blue) {
            VStack(alignment: .leading, spacing: 10) {
                WidgetHeader(title: "Recent Summary", systemImage: "sparkles")

                if let item = entry.latestItem {
                    Text(item.title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    Text(item.summary.isEmpty ? "打开 App 继续生成 AI Summary。" : item.summary)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.82))
                        .lineLimit(4)

                    HStack(spacing: 6) {
                        Text(item.mode)
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.white.opacity(0.16))
                            .clipShape(Capsule())

                        Spacer(minLength: 0)

                        Text("\(entry.payload.totalCount) 条")
                            .font(.caption2.weight(.semibold))
                    }
                    .foregroundStyle(.white.opacity(0.92))
                } else {
                    Spacer(minLength: 0)
                    Text("还没有截图记录")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                    Text("打开 App 上传截图，Widget 会显示最近 Summary。")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.82))
                        .lineLimit(3)
                    Spacer(minLength: 0)
                }
            }
        }
        .widgetURL(WidgetDeepLink.recent)
    }
}

private struct WidgetGlassContainer<Content: View>: View {
    let accent: Color
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(red: 0.07, green: 0.10, blue: 0.20),
                            accent.opacity(0.82),
                            Color(red: 0.02, green: 0.40, blue: 0.52)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    RadialGradient(
                        colors: [.white.opacity(0.34), .clear],
                        center: .topTrailing,
                        startRadius: 4,
                        endRadius: 118
                    )
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.ultraThinMaterial.opacity(0.22))
                        .padding(8)
                }
            )
            .overlay(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.18), lineWidth: 1)
                    .padding(8)
            }
            .containerBackground(for: .widget) {
                LinearGradient(
                    colors: [accent.opacity(0.95), Color(red: 0.05, green: 0.08, blue: 0.18)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
    }
}

private struct WidgetHeader: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(.white.opacity(0.18))
                .clipShape(Circle())

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.92))
                .lineLimit(1)

            Spacer(minLength: 0)
        }
    }
}

private struct SummaryLine: View {
    let item: WidgetSnapshotItem

    var body: some View {
        HStack(alignment: .top, spacing: 7) {
            Circle()
                .fill(.white.opacity(0.78))
                .frame(width: 5, height: 5)
                .padding(.top, 5)

            Text(item.summary.isEmpty ? item.title : item.summary)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.82))
                .lineLimit(2)
        }
    }
}

struct QuickOCRWidget: Widget {
    let kind = "QuickOCRWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AIScreenshotWidgetProvider()) { entry in
            QuickOCRWidgetView(entry: entry)
        }
        .configurationDisplayName("Quick OCR")
        .description("快速打开 AI Screenshot Assistant 并查看 OCR/summary 数量。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct DailySummaryWidget: Widget {
    let kind = "DailySummaryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AIScreenshotWidgetProvider()) { entry in
            DailySummaryWidgetView(entry: entry)
        }
        .configurationDisplayName("Daily Summary")
        .description("查看今日截图总结数量和摘要。")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct RecentSummaryWidget: Widget {
    let kind = "RecentSummaryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AIScreenshotWidgetProvider()) { entry in
            RecentSummaryWidgetView(entry: entry)
        }
        .configurationDisplayName("Recent Summary")
        .description("显示最近一次 AI Summary。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct AIScreenshotWidgetBundle: WidgetBundle {
    var body: some Widget {
        QuickOCRWidget()
        DailySummaryWidget()
        RecentSummaryWidget()
    }
}

private extension WidgetSnapshotPayload {
    static var placeholder: WidgetSnapshotPayload {
        WidgetSnapshotPayload(
            items: [
                WidgetSnapshotItem(
                    id: UUID(),
                    createdAt: Date(),
                    title: "会议截图重点",
                    summary: "3 个关键结论、2 个待办事项已整理完成。",
                    mode: "摘要",
                    ocrPreview: "Q2 roadmap sync: launch plan, owner, timeline..."
                ),
                WidgetSnapshotItem(
                    id: UUID(),
                    createdAt: Date(),
                    title: "付款提示",
                    summary: "余额不足，需要补充付款方式后继续。",
                    mode: "摘要",
                    ocrPreview: "Your remaining store credit is insufficient..."
                )
            ],
            totalCount: 18,
            todayCount: 3,
            updatedAt: Date()
        )
    }
}
