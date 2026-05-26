import SwiftUI

struct ShareExtensionView: View {
    @ObservedObject var viewModel: ShareExtensionViewModel
    let onCancel: () -> Void
    let onSaveAndOpen: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                preview
                summaryCard
                Spacer(minLength: 0)
                actionButton
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

    private var actionButton: some View {
        Button(action: onSaveAndOpen) {
            HStack(spacing: 10) {
                if case .recognizing = viewModel.state {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "arrow.up.forward.app.fill")
                }
                Text("保存并打开 App")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .foregroundStyle(.white)
            .background(viewModel.canSave ? Color.accentColor : Color.gray)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .disabled(!viewModel.canSave)
    }
}
