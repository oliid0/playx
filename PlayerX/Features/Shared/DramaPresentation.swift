import Foundation

/// 剧集在 UI 层的派生文案。Go 返回的字段已经归一化，但不同站源很多字段为空，
/// 页面里到处写 `if let` 会非常碎；把「有就显示、没有就退到下一档」的规则收在这里。
extension Drama {
    var episodeText: String? {
        guard let episodes, episodes > 0 else { return nil }
        return "\(episodes) 集"
    }

    var sourceName: String {
        SourceRegistry.descriptor(for: source)?.displayName ?? source
    }

    /// 详情页标题下的一行元信息：集数 · 分类 · 热度。
    var metaLine: String {
        var parts: [String] = []
        if let episodeText { parts.append(episodeText) }
        if let category, !category.isEmpty { parts.append(category) }
        if let heat = AppFormat.heat(heat) { parts.append("热度 \(heat)") }
        if parts.isEmpty { parts.append("短剧") }
        return parts.joined(separator: " · ")
    }

    /// 卡片副标题：集数 + 分类，尽量短。
    var cardSubtitle: String {
        var parts: [String] = []
        if let episodeText { parts.append(episodeText) }
        if let category, !category.isEmpty { parts.append(category) }
        if parts.isEmpty, let heat = AppFormat.heat(heat) { parts.append("热度 \(heat)") }
        return parts.joined(separator: " · ")
    }

    var tagList: [String] {
        var result = tags?.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } ?? []
        if result.isEmpty, let category, !category.isEmpty {
            result = category
                .split(whereSeparator: { $0 == "/" || $0 == "·" || $0 == "," || $0 == "，" })
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        return Array(result.prefix(6))
    }

    var releaseText: String? {
        if let releaseStatus, !releaseStatus.isEmpty { return releaseStatus }
        if let onlineDate, !onlineDate.isEmpty { return onlineDate }
        return nil
    }
}

extension HistoryEntry {
    var progress: Double {
        guard duration > 0 else { return 0 }
        return min(max(position / duration, 0), 1)
    }

    var remainingSeconds: Double {
        max(duration - position, 0)
    }

    var episodeLabel: String {
        "第 \(max(episodeIndex, 1)) 集"
    }

    var updatedText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: updatedAt, relativeTo: Date())
    }
}
