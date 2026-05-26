import SwiftUI
import UIKit

struct ZoomableImageView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ZoomableImageScrollView(image: image)
                    .ignoresSafeArea()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
    }
}

private struct ZoomableImageScrollView: UIViewRepresentable {
    let image: UIImage

    func makeUIView(context: Context) -> ZoomingImageContainer {
        ZoomingImageContainer(image: image)
    }

    func updateUIView(_ view: ZoomingImageContainer, context: Context) {
        view.setImage(image)
    }
}

private final class ZoomingImageContainer: UIView, UIScrollViewDelegate {
    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    private var currentImage: UIImage

    init(image: UIImage) {
        currentImage = image
        super.init(frame: .zero)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setImage(_ image: UIImage) {
        currentImage = image
        imageView.image = image
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.size != .zero else { return }

        scrollView.frame = bounds

        if scrollView.zoomScale == scrollView.minimumZoomScale {
            configureImageFrame()
        }
        centerImage()
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImage()
    }

    private func configure() {
        backgroundColor = .black

        scrollView.backgroundColor = .black
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 6
        scrollView.bouncesZoom = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        addSubview(scrollView)

        imageView.image = currentImage
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        scrollView.addSubview(imageView)

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
    }

    private func configureImageFrame() {
        let imageSize = currentImage.size
        guard imageSize.width > 0, imageSize.height > 0 else { return }

        let widthScale = bounds.width / imageSize.width
        let heightScale = bounds.height / imageSize.height
        let fitScale = min(widthScale, heightScale)
        let fittedSize = CGSize(width: imageSize.width * fitScale, height: imageSize.height * fitScale)

        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 6
        scrollView.zoomScale = 1
        imageView.frame = CGRect(origin: .zero, size: fittedSize)
        scrollView.contentSize = fittedSize
    }

    private func centerImage() {
        let horizontalInset = max((bounds.width - scrollView.contentSize.width) / 2, 0)
        let verticalInset = max((bounds.height - scrollView.contentSize.height) / 2, 0)
        scrollView.contentInset = UIEdgeInsets(top: verticalInset, left: horizontalInset, bottom: verticalInset, right: horizontalInset)
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
            return
        }

        let targetScale = min(scrollView.maximumZoomScale, 3)
        let point = gesture.location(in: imageView)
        let width = scrollView.bounds.width / targetScale
        let height = scrollView.bounds.height / targetScale
        let rect = CGRect(x: point.x - width / 2, y: point.y - height / 2, width: width, height: height)
        scrollView.zoom(to: rect, animated: true)
    }
}
