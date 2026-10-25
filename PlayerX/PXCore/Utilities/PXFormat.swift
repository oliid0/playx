import Foundation

enum PXFormat {
    static func runtime(minutes: Int) -> String {
        guard minutes > 0 else { return "" }
        let hours = minutes / 60
        let rest = minutes % 60
        if hours > 0 { return rest > 0 ? "\(hours) 小时 \(rest) 分" : "\(hours) 小时" }
        return "\(minutes) 分钟"
    }

    static func time(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "00:00" }
        let total = Int(seconds.rounded(.down))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }

    static func timeLeft(current: Double, duration: Double) -> String {
        guard duration > current else { return "已结束" }
        return "剩余 \(time(duration - current))"
    }

    static func byteCount(_ value: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: max(0, value))
    }

    static func rating(_ value: Double?) -> String {
        guard let value, value > 0 else { return "暂无评分" }
        return String(format: "%.1f", value)
    }

    static func voteCount(_ value: Int?) -> String {
        guard let value, value > 0 else { return "" }
        if value >= 10_000 { return String(format: "%.1f 万", Double(value) / 10_000) }
        return "\(value)"
    }

    static func percent(_ value: Double) -> String {
        "\(Int((min(max(value, 0), 1) * 100).rounded()))%"
    }

    static func date(_ raw: String?) -> Date? {
        guard let raw, !raw.isEmpty else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: raw)
    }

    static func airDate(_ raw: String?) -> String {
        guard let date = date(raw) else { return raw ?? "" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: date)
    }

    static func relative(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    static func episodeTitle(index: Int, title: String?) -> String {
        if let title, !title.isEmpty { return "第 \(index) 集 · \(title)" }
        return "第 \(index) 集"
    }
}
