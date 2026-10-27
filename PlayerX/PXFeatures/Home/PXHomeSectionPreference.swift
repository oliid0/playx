import Foundation

enum PXHomeSection: String, CaseIterable, Identifiable {
    case continueWatching
    case nextUp
    case latest
    case libraries

    var id: String { rawValue }

    var title: String {
        switch self {
        case .continueWatching: "继续观看"
        case .nextUp: "接下来看"
        case .latest: "最近添加"
        case .libraries: "媒体库"
        }
    }

    var subtitle: String {
        switch self {
        case .continueWatching: "播放历史"
        case .nextUp: "收藏与在看"
        case .latest: "各媒体库最新内容"
        case .libraries: "站源与外部媒体源"
        }
    }
}

enum PXHomeSectionPreference {
    static let storageKey = "playerx.home.sections.v1"

    static func hidden(from raw: String) -> Set<PXHomeSection> {
        Set(raw.split(separator: ",").compactMap { PXHomeSection(rawValue: String($0)) })
    }

    static func raw(from hidden: Set<PXHomeSection>) -> String {
        PXHomeSection.allCases.filter { hidden.contains($0) }.map(\.rawValue).joined(separator: ",")
    }
}
