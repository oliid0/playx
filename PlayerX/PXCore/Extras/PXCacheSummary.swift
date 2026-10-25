import Foundation
struct PXCacheSummary {
    var metadataCount: Int
    var imageCount: Int
    var downloadsBytes: Int64
    var text: String {
        "元数据 \(metadataCount) 条 · 图片 \(imageCount) 张 · 离线 \(PXFormat.byteCount(downloadsBytes))"
    }
}
