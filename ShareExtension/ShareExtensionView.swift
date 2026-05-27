import SwiftUI

struct ShareExtensionView: View {
    @ObservedObject var viewModel: ShareExtensionViewModel
    let onCancel: () -> Void
    let onSave: () -> Void
    let onOpenApp: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                preview
                summaryCard
                Spacer(minLength: 0)
                SaveButton(
                    title: viewModel.state == .saved ? "已保存" : "保存",
                    isEnabled: viewModel.canSave,
                    isLoading: viewModel.state == .recognizing,
                    action: onSave
                )
                OpenAppButton(
                    isEnabled: viewModel.state == .saved,
                    action: onOpenApp
                )
            }
            .padding(18)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("AI 截图助手")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消", action: onCancel)
                }
            }
        }
    }

    private var preview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))

            if let image = viewModel.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 38))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 210)
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("AI 总结", systemImage: "sparkles")
                .font(.headline)

            Text(viewModel.statusText)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if !viewModel.summary.isEmpty {
                Divider()
                Text(viewModel.summary)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if !viewModel.ocrText.isEmpty {
                Divider()
                Text(viewModel.ocrText)
                    .font(.footnote)
                    .foregroundStyle(.primary)
                    .lineLimit(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct SaveButton: View {
    let title: String
    let isEnabled: Bool
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label {
                Text(title)
                    .fontWeight(.semibold)
            } icon: {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "square.and.arrow.down.fill")
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .foregroundStyle(.white)
            .background(isEnabled ? Color.accentColor : Color.gray)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .disabled(!isEnabled)
    }
}

struct OpenAppButton: View {
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("打开 App", systemImage: "arrow.up.forward.app.fill")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .foregroundStyle(isEnabled ? Color.accentColor : Color.gray)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .disabled(!isEnabled)
    }
}
