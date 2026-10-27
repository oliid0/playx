import Foundation

enum PXUEpisodeSort: String, CaseIterable, Identifiable {
    case ascending, descending
    var id: String { rawValue }
    var title: String { self == .ascending ? "正序" : "倒序" }
}
