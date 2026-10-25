import Foundation

/// 站源标题 → TMDB 搜索结果的纯逻辑匹配。先看标题相似度，再看年份和
/// 剧集/电影类型，最后用热度做同分裁决；不依赖任何 UI 状态，方便测试。
enum PXTMDbMatcher {
    struct Candidate {
        var result: PXTMDbSearchResult
        var score: Double
    }

    static func best(
        for drama: Drama,
        results: [PXTMDbSearchResult],
        kind: PXMediaKind
    ) -> PXTMDbSearchResult? {
        candidates(for: drama, results: results, kind: kind).first?.result
    }

    static func candidates(
        for drama: Drama,
        results: [PXTMDbSearchResult],
        kind: PXMediaKind
    ) -> [Candidate] {
        let title = drama.title
        let year = drama.pxYear
        let expectedMovie = kind == .movie
        return results.compactMap { item in
            let candidateTitle = item.displayTitle
            guard !candidateTitle.isEmpty else { return nil }
            let similarity = max(
                PXNormalizer.similarity(title, candidateTitle),
                PXNormalizer.similarity(title, item.originalTitle ?? item.originalName ?? "")
            )
            var score = similarity * 100
            if PXNormalizer.title(title) == PXNormalizer.title(candidateTitle) { score += 35 }
            if candidateTitle.contains(title) || title.contains(candidateTitle) { score += 12 }
            if let year, let candidateYear = item.year {
                let delta = abs(year - candidateYear)
                score += delta == 0 ? 18 : (delta <= 1 ? 8 : -Double(delta) * 2)
            }
            let isMovie = item.mediaType == "movie"
            if expectedMovie == isMovie { score += 10 } else if item.mediaType != nil { score -= 8 }
            if kind == .anime, item.originalLanguage == "ja" { score += 6 }
            score += min((item.popularity ?? 0) / 120, 4)
            return Candidate(result: item, score: score)
        }
        .sorted { $0.score > $1.score }
    }

    static func accepted(_ candidate: Candidate) -> Bool {
        candidate.score >= 48
    }
}
