import SwiftUI
import PhotosUI

struct GroupDetailView: View {

    let group: PhotoGroup
    let assets: [PHAsset]

    @State private var selectedAssetIndex: Int? = nil

    var body: some View {
        List(assets.indices, id: \.self) { index in
            Button(action: {
                selectedAssetIndex = index
            }) {
                AssetThumbnailView(asset: assets[index])
                    .frame(width: 80, height: 80)
                    .clipped()
            }
        }
        .sheet(item: $selectedAssetIndex) { index in
            ImageDetailView(assets: assets, currentIndex: index)
        }
        .navigationTitle(group.rawValue.capitalized)
    }
}

// Helper view to show thumbnail image of a PHAsset

struct AssetThumbnailView: UIViewRepresentable {
    let asset: PHAsset
    let imageManager = PHCachingImageManager()

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true

        let size = CGSize(width: 80, height: 80)
        imageManager.requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: nil) { image, _ in
            imageView.image = image
        }

        return imageView
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {
        // No update needed here because PHCachingImageManager handles caching
    }
}

extension Int: Identifiable {
    public var id: Int {
        self
    }
}
