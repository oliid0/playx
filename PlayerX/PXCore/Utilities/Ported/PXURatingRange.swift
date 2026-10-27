import Foundation

struct PXURatingRange: Equatable {
    var minimum: Double
    static let any = PXURatingRange(minimum: 0)
    func contains(_ rating: Double?) -> Bool { (rating ?? 0) >= minimum }
    var label: String { minimum <= 0 ? "全部评分" : "\(String(format: "%.1f", minimum))+ 分" }
}
