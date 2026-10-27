import Foundation

enum PXURatingFormatter {
    static func text(_ rating: Double?) -> String {
        guard let rating, rating > 0 else { return "—" }
        return String(format: "%.1f", rating)
    }
    static func percent(_ rating: Double?) -> String {
        guard let rating, rating > 0 else { return "—" }
        return "\(Int(rating * 10))%"
    }
}
