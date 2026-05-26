import SwiftUI

struct ProcessingView: View {
    let step: ResultViewModel.Step

    var body: some View {
        VStack(spacing: 26) {
            ZStack {
                Circle().fill(DS.ColorToken.primary.opacity(0.13)).frame(width: 118, height: 118)
                Circle().fill(LinearGradient(colors: [DS.ColorToken.primary.opacity(0.9), DS.ColorToken.primary2], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 82, height: 82)
                Image(systemName: "sparkles").font(.system(size: 34, weight: .bold)).foregroundStyle(.white)
            }
            Text("正在分析截图...")
                .font(.title3.bold())
            VStack(alignment: .leading, spacing: 16) {
                row("识别截图文字", done: isAtLeast(.analyzing), active: step == .ocr)
                row("理解内容结构", done: isAtLeast(.summary), active: step == .analyzing)
                row("生成 AI 总结", done: step == .done, active: step == .summary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text("通常只需要几秒钟。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(28)
    }

    private func row(_ title: String, done: Bool, active: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: done ? "checkmark.circle.fill" : active ? "circle.dotted" : "circle")
                .foregroundStyle(done || active ? DS.ColorToken.primary : .gray.opacity(0.5))
            Text(title).font(.subheadline)
        }
    }

    private func isAtLeast(_ target: ResultViewModel.Step) -> Bool {
        let order: [ResultViewModel.Step] = [.idle, .ocr, .analyzing, .summary, .done]
        return (order.firstIndex(of: step) ?? 0) >= (order.firstIndex(of: target) ?? 0)
    }
}
