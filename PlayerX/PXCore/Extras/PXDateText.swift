import Foundation
enum PXDateText {
    static func year(_ date: Date) -> String { String(Calendar.current.component(.year, from: date)) }
    static func short(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }
    static func compact(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds > 0 else { return "0 分钟" }
        let minutes = Int(seconds / 60)
        if minutes >= 60 { return "\(minutes / 60) 小时 \(minutes % 60) 分" }
        return "\(minutes) 分钟"
    }
}
