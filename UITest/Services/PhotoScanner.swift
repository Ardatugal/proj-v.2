import Photos

class PhotoScanner {

    private var allAssets: [PHAsset] = []
    private(set) var groupCounts: [PhotoGroup: Int] = [:]
    private var groupedAssets: [PhotoGroup: [PHAsset]] = [:]

    private var processedCount = 0
    private var totalCount = 0

    // Callbacks
    var onProgressUpdate: ((_ processed: Int, _ total: Int, _ groupCounts: [PhotoGroup: Int]) -> Void)?
    var onScanComplete: (() -> Void)?

    private let scanQueue = DispatchQueue(label: "photo.scan.queue", qos: .userInitiated)

    func startScan() {
        // Reset state
        groupCounts = [:]
        groupedAssets = [:]
        processedCount = 0
        totalCount = 0

        // Fetch assets (images only)
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        let fetchedAssets = PHAsset.fetchAssets(with: fetchOptions)
        totalCount = fetchedAssets.count

        // Store assets in array for easier access
        allAssets = []
        fetchedAssets.enumerateObjects { asset, _, _ in
            self.allAssets.append(asset)
        }

        // Scan asynchronously
        scanQueue.async {
            for asset in self.allAssets {
                autoreleasepool {
                    let hashValue = asset.reliableHash()
                    let group = PhotoGroup.group(for: hashValue)

                    self.groupCounts[group, default: 0] += 1
                    self.groupedAssets[group, default: []].append(asset)

                    self.processedCount += 1

                    DispatchQueue.main.async {
                        self.onProgressUpdate?(self.processedCount, self.totalCount, self.groupCounts)
                    }
                }
            }

            DispatchQueue.main.async {
                self.onScanComplete?()
            }
        }
    }

    func assetsForGroup(_ group: PhotoGroup) -> [PHAsset] {
        return groupedAssets[group] ?? []
    }
}
