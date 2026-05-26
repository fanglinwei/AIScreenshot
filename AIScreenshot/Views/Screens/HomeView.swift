import SwiftUI
import PhotosUI
import UIKit

struct HomeView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var selectedMode: SummaryMode = .summary
    @State private var showImageSourceDialog = false
    @State private var showPhotoPicker = false
    @State private var showCamera = false
    @State private var showCameraUnavailableAlert = false
    @State private var showResult = false
    @EnvironmentObject private var historyStore: HistoryStore

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    heroUpload
                    modePicker
                    recentList
                }
                .padding(20)
            }
            .background(DS.ColorToken.background.ignoresSafeArea())

            if showImageSourceDialog {
                imageSourceSheet
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.86), value: showImageSourceDialog)
        .navigationDestination(isPresented: $showResult) {
            if let selectedImage {
                ResultView(image: selectedImage, mode: selectedMode)
            }
        }
        .navigationDestination(item: $historyStore.pendingImportedItem) { item in
            HistoryDetailView(item: item)
        }
        .onChange(of: selectedItem) { _, item in
            Task { await loadImage(from: item) }
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedItem, matching: .images)
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { image in
                selectedImage = image
                showResult = true
            }
        }
        .alert("无法拍照", isPresented: $showCameraUnavailableAlert) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text("当前设备不支持相机拍摄。")
        }
    }

    private var imageSourceSheet: some View {
        ZStack(alignment: .bottom) {
            Color.clear
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    showImageSourceDialog = false
                }

            VStack(spacing: 12) {
                imageSourceButton(title: "选择图片", systemImage: "photo") {
                    showImageSourceDialog = false
                    showPhotoPicker = true
                }

                imageSourceButton(title: "拍照", systemImage: "camera") {
                    showImageSourceDialog = false
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        showCamera = true
                    } else {
                        showCameraUnavailableAlert = true
                    }
                }
            }
            .padding(12)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
                    .stroke(DS.ColorToken.border, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.16), radius: 22, y: 10)
            .padding(.horizontal, 18)
            .padding(.bottom, 12)
        }
    }

    private func imageSourceButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(DS.ColorToken.primary)

                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(DS.ColorToken.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .padding(.horizontal, 18)
            .background(DS.ColorToken.card.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("AI 截图")
                    .font(.largeTitle.bold())
                    .foregroundStyle(DS.ColorToken.primary)
                Text("助手")
                    .font(.largeTitle.bold())
                    .foregroundStyle(DS.ColorToken.textPrimary)
                Text("从截图中提取文字，并快速生成摘要、翻译或待办。")
                    .font(.subheadline)
                    .foregroundStyle(DS.ColorToken.textSecondary)
            }
            Spacer()
            Image(systemName: "crown.fill")
                .foregroundStyle(.orange)
                .padding(10)
        }
    }

    private var heroUpload: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(DS.ColorToken.primary)
            Text("上传截图")
                .font(.headline)
                .foregroundStyle(DS.ColorToken.textPrimary)
            Text("支持 PNG、JPG、HEIC")
                .font(.caption)
                .foregroundStyle(DS.ColorToken.textSecondary)

            Button {
                showImageSourceDialog = true
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("选择图片")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(LinearGradient(colors: [DS.ColorToken.primary, DS.ColorToken.primary2], startPoint: .leading, endPoint: .trailing))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(26)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.xl, style: .continuous)
                .fill(DS.ColorToken.elevatedCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.xl, style: .continuous)
                .stroke(style: StrokeStyle(lineWidth: 1.4, dash: [7]))
                .foregroundStyle(DS.ColorToken.primary.opacity(0.45))
        )
    }

    private var modePicker: some View {
        Picker("处理模式", selection: $selectedMode) {
            ForEach(SummaryMode.allCases) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }

    private var recentList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("最近记录").font(.headline)
                    .foregroundStyle(DS.ColorToken.textPrimary)
                Spacer()
                NavigationLink("查看全部") { HistoryView() }
                    .font(.caption.weight(.semibold))
            }
            if historyStore.items.isEmpty {
                Text("暂无最近截图。")
                    .foregroundStyle(DS.ColorToken.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()
            } else {
                ForEach(historyStore.items.prefix(3)) { item in
                    NavigationLink { HistoryDetailView(item: item) } label: {
                        HStack {
                            recentThumbnail(for: item)
                            VStack(alignment: .leading) {
                                Text(item.title).font(.subheadline.weight(.semibold)).lineLimit(1)
                                Text(item.createdAt, style: .date).font(.caption).foregroundStyle(DS.ColorToken.textSecondary)
                            }
                            Spacer()
                            Text(item.mode.rawValue)
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 8).padding(.vertical, 5)
                                .background(DS.ColorToken.primary.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        .foregroundStyle(.primary)
                        .cardStyle(radius: DS.Radius.md)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func recentThumbnail(for item: OCRResult) -> some View {
        if let image = historyStore.image(for: item) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 42, height: 42)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous))
        } else {
            Image(systemName: "doc.text.viewfinder")
                .foregroundStyle(DS.ColorToken.primary)
                .frame(width: 42, height: 42)
                .background(DS.ColorToken.primary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous))
        }
    }

    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                await MainActor.run {
                    selectedImage = image
                    showResult = true
                }
            }
        } catch { print(error.localizedDescription) }
    }
}
