import SwiftUI
import PhotosUI

struct ImageDetailView: View {

    let assets: [PHAsset]
    @State private var currentIndex: Int

    let imageManager = PHCachingImageManager()

    init(assets: [PHAsset], currentIndex: Int) {
        self.assets = assets
        _currentIndex = State(initialValue: currentIndex)
    }

    var body: some View {
        VStack {
            if assets.indices.contains(currentIndex) {
                ZoomableImageView(asset: assets[currentIndex])
            } else {
                Text("No Image")
                    .foregroundColor(.secondary)
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width < -50 {
                        // Swipe left -> next image
                        if currentIndex < assets.count - 1 {
                            currentIndex += 1
                        }
                    } else if value.translation.width > 50 {
                        // Swipe right -> previous image
                        if currentIndex > 0 {
                            currentIndex -= 1
                        }
                    }
                }
        )
        .navigationBarTitleDisplayMode(.inline)
    }
}

// ZoomableImageView: UIViewRepresentable showing a full-size zoomable image of PHAsset

struct ZoomableImageView: UIViewRepresentable {
    let asset: PHAsset
    let imageManager = PHCachingImageManager()

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.maximumZoomScale = 5.0
        scrollView.minimumZoomScale = 1.0
        scrollView.delegate = context.coordinator
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false

        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tag = 100  // To identify it later
        imageView.frame = scrollView.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.addSubview(imageView)

        loadImage(into: imageView)

        return scrollView
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        if let imageView = uiView.viewWithTag(100) as? UIImageView {
            loadImage(into: imageView)
            imageView.frame = uiView.bounds
        }
    }

    func loadImage(into imageView: UIImageView) {
        let targetSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: nil) { image, _ in
            imageView.image = image
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            scrollView.viewWithTag(100)
        }
    }
}
