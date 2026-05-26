import SwiftUI

struct ImagePreviewThumbnail: View {
    let image: UIImage
    var height: CGFloat = 180
    var showsFullImage = false
    let action: () -> Void

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: showsFullImage ? .fit : .fill)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .clipped()

            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .padding(8)
                .background(.black.opacity(0.45))
                .clipShape(Circle())
                .padding(10)
                .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous))
        .contentShape(Rectangle())
        .shadow(color: .black.opacity(0.12), radius: 18, y: 8)
        .highPriorityGesture(
            TapGesture().onEnded {
                action()
            }
        )
    }
}
