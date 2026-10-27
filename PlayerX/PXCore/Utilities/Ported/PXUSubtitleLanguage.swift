import Foundation

enum PXUSubtitleLanguage: String, CaseIterable, Identifiable {
    case automatic, chineseSimplified, chineseTraditional, english, japanese
    var id: String { rawValue }
    var title: String {
        switch self {
        case .automatic: "自动"
        case .chineseSimplified: "简体中文"
        case .chineseTraditional: "繁體中文"
        case .english: "English"
        case .japanese: "日本語"
        }
    }
}
