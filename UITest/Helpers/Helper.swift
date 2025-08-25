import CryptoKit
import Photos

extension PHAsset {
    // Thread.sleep is added to simulate variability in hash calculation time
    func reliableHash() -> Double {
        Thread.sleep(forTimeInterval: Double.random(in: 0.01 ... 0.02))
        let data = Data(localIdentifier.utf8)
        let digest = SHA256.hash(data: data)
        let prefix = digest.prefix(8)
        let value = prefix.reduce(UInt64(0)) { ($0 << 8) | UInt64($1) }
        return Double(value) / Double(UInt64.max)
    }
}
