import Foundation

struct PXPlaybackRateController {
    static let rates: [Double] = [0.5, 0.75, 1, 1.25, 1.5, 1.75, 2]
    static func normalized(_ rate: Double) -> Double {
        rates.contains(rate) ? rate : 1
    }
    static func next(after rate: Double) -> Double {
        guard let index = rates.firstIndex(of: normalized(rate)) else { return 1 }
        return rates[(index + 1) % rates.count]
    }
    static func label(_ rate: Double) -> String {
        rate == 1 ? "正常" : String(format: "%.2gx", rate)
    }
}
