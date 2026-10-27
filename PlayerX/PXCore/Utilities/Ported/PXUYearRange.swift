import Foundation

struct PXUYearRange: Equatable {
    var lower: Int
    var upper: Int
    static let any = PXUYearRange(lower: 0, upper: 9999)
    func contains(_ year: Int) -> Bool { year >= lower && year <= upper }
    var label: String { lower == 0 && upper == 9999 ? "全部年份" : "\(lower)–\(upper)" }
}
