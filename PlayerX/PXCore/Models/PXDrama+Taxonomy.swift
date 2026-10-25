import Foundation

extension Drama {
    /// 站源内容到统一媒体分类的映射。短剧站源的“电视剧”经常也包含横屏剧，
    /// 因此只在标题/分类明确出现“短剧”或来源本身是竖屏短剧站时才归为短剧。
    var pxKind: PXMediaKind {
        let category = (category ?? "").lowercased()
        let tagText = (tags ?? []).joined(separator: " ").lowercased()
        let haystack = "\(title) \(category) \(tagText)"
        if haystack.contains("动漫") || haystack.contains("动画") || haystack.contains("番剧")
            || haystack.contains("anime") {
            return .anime
        }
        if haystack.contains("综艺") || haystack.contains("真人秀") {
            return .variety
        }
        if haystack.contains("纪录") || haystack.contains("documentary") {
            return .documentary
        }
        if haystack.contains("短剧") || ["hongguo", "hanxiaoquan", "sorani"].contains(source) {
            return .shortDrama
        }
        if haystack.contains("电影") || haystack.contains("片") || haystack.contains("movie") {
            return .movie
        }
        return .series
    }

    /// 年份：优先 `onlineDate` 的前四位，其次 tags 里的四位数字。
    var pxYear: Int? {
        if let date = onlineDate, let year = Self.firstYear(in: date) { return year }
        for tag in tags ?? [] {
            if let year = Self.firstYear(in: tag) { return year }
        }
        return nil
    }

    var pxGenres: [String] {
        var values: [String] = []
        if let category, !category.isEmpty { values.append(category) }
        values.append(contentsOf: tags ?? [])
        var seen = Set<String>()
        return values.filter { value in
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, seen.insert(trimmed).inserted else { return false }
            return true
        }
    }

    var pxEpisodeCount: Int? {
        guard let episodes, episodes > 0 else { return nil }
        return episodes
    }

    var pxDisplaySubtitle: String {
        var parts: [String] = []
        if let year = pxYear { parts.append(String(year)) }
        if let count = pxEpisodeCount, pxKind.isEpisodic { parts.append("全 \(count) 集") }
        parts.append(pxKind.title)
        return parts.joined(separator: " · ")
    }

    var pxShareURL: URL? {
        let source = sourceId
        guard !source.isEmpty else { return nil }
        var components = URLComponents()
        components.scheme = "playerx"
        components.host = "detail"
        components.queryItems = [
            URLQueryItem(name: "source", value: source),
            URLQueryItem(name: "id", value: sourceId),
            URLQueryItem(name: "title", value: title),
        ]
        return components.url
    }

    private static func firstYear(in text: String) -> Int? {
        guard let range = text.range(of: #"20[0-9]{2}"#, options: .regularExpression) else { return nil }
        return Int(text[range])
    }
}
