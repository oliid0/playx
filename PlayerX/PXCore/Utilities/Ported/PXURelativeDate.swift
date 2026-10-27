import Foundation

enum PXURelativeDate {
    static func text(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    static func day(_ string: String?) -> String {
        guard let string, !string.isEmpty else { return "—" }
        return String(string.prefix(10))
    }
}
