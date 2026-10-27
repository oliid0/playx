import Foundation

enum PXUDurationFormatter {
    static func minutes(_ value: Int?) -> String {
        guard let value, value > 0 else { return "—" }
        if value < 60 { return "\(value) 分钟" }
        let h = value / 60, m = value % 60
        return m == 0 ? "\(h) 小时" : "\(h) 小时 \(m) 分"
    }
}
