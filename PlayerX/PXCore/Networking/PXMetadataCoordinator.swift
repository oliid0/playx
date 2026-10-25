import Foundation
import Combine

/// 详情页元数据的入口：先读本地对应关系与缓存，再按需搜索 TMDB、拉详情，
/// 最后把结果写给 UI。网络失败不会抹掉已有缓存，手动匹配优先级最高。
@MainActor
final class PXMetadataCoordinator: ObservableObject {
    static let shared = PXMetadataCoordinator()

    @Published private(set) var lastError: String?
    @Published private(set) var isMatching = false

    private let client: PXTMDbClient
    private let cache: PXMetadataCache
    private let settings: PXAppSettings
    private var inFlight: [String: Task<PXMediaMetadata?, Never>] = [:]
    private var failedAt: [String: Date] = [:]

    init(
        client: PXTMDbClient = PXTMDbClient(),
        cache: PXMetadataCache = .shared,
        settings: PXAppSettings = .shared
    ) {
        self.client = client
        self.cache = cache
        self.settings = settings
    }

    var isEnabled: Bool {
        settings.tmdbEnabled && !settings.effectiveTMDbToken.isEmpty
    }

    func cachedLink(for drama: Drama) async -> PXMediaMetadata? {
        guard let link = await cache.link(for: drama.id) else { return nil }
        return await cache.metadata(tmdbID: link.tmdbID, kind: link.kind, language: settings.tmdbLanguage)
    }

    /// 详情页调用。`allowNetwork == false` 时只读缓存，用于首屏避免闪网络。
    func metadata(for drama: Drama, allowNetwork: Bool = true) async -> PXMediaMetadata? {
        guard isEnabled else { return nil }
        if let existing = await cachedLink(for: drama) {
            if allowNetwork, existing.fetchedAt.timeIntervalSinceNow < -60 * 60 * 24 * 7 {
                return await refresh(drama: drama, metadata: existing) ?? existing
            }
            return existing
        }
        guard allowNetwork else { return nil }
        if let task = inFlight[drama.id] { return await task.value }

        let task = Task<PXMediaMetadata?, Never> { [weak self] in
            guard let self else { return nil }
            return await self.resolve(drama: drama)
        }
        inFlight[drama.id] = task
        let result = await task.value
        inFlight[drama.id] = nil
        return result
    }

    func refresh(drama: Drama, metadata: PXMediaMetadata? = nil) async -> PXMediaMetadata? {
        guard isEnabled else { return nil }
        let resolvedLink: (Int, PXMediaKind)?
        if let metadata {
            resolvedLink = (metadata.tmdbID, metadata.mediaType)
        } else {
            resolvedLink = await cache.link(for: drama.id)
        }
        guard let link = resolvedLink else { return await self.metadata(for: drama) }
        do {
            let detail = try await client.detail(
                tmdbID: link.0,
                kind: link.1,
                language: settings.tmdbLanguage,
                token: settings.effectiveTMDbToken
            )
            guard let mapped = PXTMDbMapper.metadata(
                from: detail, kind: link.1, language: settings.tmdbLanguage
            ) else { return metadata }
            await cache.store(mapped)
            lastError = nil
            failedAt[drama.id] = nil
            return mapped
        } catch {
            lastError = error.localizedDescription
            return metadata
        }
    }

    func search(query: String, kind: PXMediaKind, year: Int? = nil) async -> [PXTMDbSearchResult] {
        guard isEnabled, !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        do {
            let results = try await client.search(
                query: query,
                kind: kind,
                year: year,
                language: settings.tmdbLanguage,
                token: settings.effectiveTMDbToken
            )
            lastError = nil
            return results
        } catch {
            lastError = error.localizedDescription
            return []
        }
    }

    func searchMulti(query: String) async -> [PXTMDbSearchResult] {
        guard isEnabled, !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        do {
            return try await client.multiSearch(
                query: query,
                language: settings.tmdbLanguage,
                token: settings.effectiveTMDbToken
            )
        } catch {
            lastError = error.localizedDescription
            return []
        }
    }

    func season(tvID: Int, seasonNumber: Int) async -> PXSeasonInfo? {
        guard isEnabled else { return nil }
        if let cached = await cache.season(
            tvID: tvID, season: seasonNumber, language: settings.tmdbLanguage
        ) { return cached }
        do {
            let dto = try await client.season(
                tvID: tvID,
                seasonNumber: seasonNumber,
                language: settings.tmdbLanguage,
                token: settings.effectiveTMDbToken
            )
            let season = PXTMDbMapper.season(from: dto, fallbackNumber: seasonNumber)
            await cache.store(season: season, tvID: tvID, language: settings.tmdbLanguage)
            return season
        } catch {
            lastError = error.localizedDescription
            return nil
        }
    }

    func manuallyMatch(drama: Drama, result: PXTMDbSearchResult, kind: PXMediaKind) async -> PXMediaMetadata? {
        isMatching = true
        defer { isMatching = false }
        let resolvedKind = result.mediaKind(fallback: kind)
        await cache.saveLink(dramaID: drama.id, tmdbID: result.id, kind: resolvedKind, source: "manual")
        return await refresh(drama: drama, metadata: PXMediaMetadata(
            tmdbID: result.id,
            mediaType: resolvedKind,
            title: result.displayTitle
        ))
    }

    func clearMatch(drama: Drama) async {
        await cache.removeLink(dramaID: drama.id)
    }

    func detail(tmdbID: Int, kind: PXMediaKind) async -> PXMediaMetadata? {
        guard isEnabled else { return nil }
        if let cached = await cache.metadata(
            tmdbID: tmdbID, kind: kind, language: settings.tmdbLanguage
        ) { return cached }
        do {
            let dto = try await client.detail(
                tmdbID: tmdbID, kind: kind,
                language: settings.tmdbLanguage,
                token: settings.effectiveTMDbToken
            )
            guard let metadata = PXTMDbMapper.metadata(
                from: dto, kind: kind, language: settings.tmdbLanguage
            ) else { return nil }
            await cache.store(metadata)
            return metadata
        } catch {
            lastError = error.localizedDescription
            return nil
        }
    }

    func trending() async -> [PXTMDbSearchResult] {
        guard isEnabled else { return [] }
        return (try? await client.trending(
            language: settings.tmdbLanguage,
            token: settings.effectiveTMDbToken
        )) ?? []
    }

    func discover(kind: PXMediaKind, genreID: Int? = nil, page: Int = 1) async -> [PXTMDbSearchResult] {
        guard isEnabled else { return [] }
        return (try? await client.discover(
            kind: kind,
            genreID: genreID,
            language: settings.tmdbLanguage,
            token: settings.effectiveTMDbToken,
            page: page
        )) ?? []
    }

    private func resolve(drama: Drama) async -> PXMediaMetadata? {
        // 十分钟内失败过就不再自动重试，避免详情页反复打开时打满额度。
        if let failed = failedAt[drama.id], Date().timeIntervalSince(failed) < 600 { return nil }
        isMatching = true
        defer { isMatching = false }

        var seen = Set<Int>()
        var candidates: [PXTMDbSearchResult] = []
        let kind = drama.pxKind
        let queries = [drama.title, cleanTitle(drama.title)].filter { !$0.isEmpty }
        let kinds: [PXMediaKind] = kind == .movie ? [.movie] : [kind, .movie]

        for query in queries {
            for searchKind in kinds {
                let results = await search(query: query, kind: searchKind, year: drama.pxYear)
                for item in results where seen.insert(item.id).inserted {
                    candidates.append(item)
                }
                if !candidates.isEmpty {
                    let ranked = PXTMDbMatcher.candidates(for: drama, results: candidates, kind: kind)
                    if let best = ranked.first, PXTMDbMatcher.accepted(best) {
                        return await attach(drama: drama, result: best.result, kind: kind)
                    }
                    break
                }
            }
            if !candidates.isEmpty { break }
        }

        let ranked = PXTMDbMatcher.candidates(for: drama, results: candidates, kind: kind)
        guard let best = ranked.first, PXTMDbMatcher.accepted(best) else {
            failedAt[drama.id] = Date()
            return nil
        }
        return await attach(drama: drama, result: best.result, kind: kind)
    }

    private func attach(drama: Drama, result: PXTMDbSearchResult, kind: PXMediaKind) async -> PXMediaMetadata? {
        let resolvedKind = result.mediaKind(fallback: kind)
        await cache.saveLink(
            dramaID: drama.id, tmdbID: result.id, kind: resolvedKind, source: "auto"
        )
        do {
            let dto = try await client.detail(
                tmdbID: result.id, kind: resolvedKind,
                language: settings.tmdbLanguage,
                token: settings.effectiveTMDbToken
            )
            guard let metadata = PXTMDbMapper.metadata(
                from: dto, kind: resolvedKind, language: settings.tmdbLanguage
            ) else { return nil }
            await cache.store(metadata)
            failedAt[drama.id] = nil
            return metadata
        } catch {
            lastError = error.localizedDescription
            failedAt[drama.id] = Date()
            return nil
        }
    }

    private func cleanTitle(_ title: String) -> String {
        var result = title
        result = result.replacingOccurrences(
            of: #"\s*[\(\[]?(第[一二三四五六七八九十0-9]+季|Season\s*[0-9]+)[\)\]]?"#,
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        result = result.replacingOccurrences(
            of: #"\s*(全集|完结|HD|4K|1080P|国语|粤语|中字)$"#,
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
