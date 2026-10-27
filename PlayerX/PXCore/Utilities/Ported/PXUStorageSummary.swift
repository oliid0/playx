import Foundation

struct PXUStorageSummary {
    var total: Int64
    var used: Int64
    var free: Int64
    var fraction: Double { total > 0 ? min(max(Double(used) / Double(total), 0), 1) : 0 }
    var text: String { "\(PXUByteFormatter.text(used)) / \(PXUByteFormatter.text(total))" }
}
