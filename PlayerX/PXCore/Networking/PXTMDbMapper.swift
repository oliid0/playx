import Foundation

enum PXTMDbMapper {
    static func metadata(from dto: PXTMDbDetailDTO, kind requestedKind: PXMediaKind, language: String) -> PXMediaMetadata? {
        let title = dto.title ?? dto.name ?? dto.originalTitle ?? dto.originalName ?? ""
        guard !title.isEmpty else { return nil }
        let genres = dto.genres?.map(\.name) ?? []
        let isAnimation = genres.contains { $0.contains("动画") || $0.lowercased() == "animation" }
        let kind: PXMediaKind
        if requestedKind == .anime {
            kind = .anime
        } else if dto.originalLanguage == "ja" && isAnimation {
            kind = .anime
        } else {
            kind = requestedKind
        }
        let logo = chooseLogo(dto.images?.logos, language: language)
        let cast = (dto.credits?.cast ?? [])
            .sorted { ($0.order ?? 999) < ($1.order ?? 999) }
            .prefix(24)
            .map {
                PXCastMember(
                    id: $0.id,
                    name: $0.name,
                    character: $0.character,
                    department: "Acting",
                    profilePath: $0.profilePath
                )
            }
        let crew = (dto.credits?.crew ?? [])
            .filter { ["Director", "Creator", "Writer", "Screenplay", "Producer"].contains($0.job ?? "") || ["Directing", "Writing"].contains($0.department ?? "") }
            .prefix(16)
            .map {
                PXCastMember(
                    id: $0.id,
                    name: $0.name,
                    department: $0.department,
                    job: localizedJob($0.job),
                    profilePath: $0.profilePath
                )
            }
        let seasons = (dto.seasons ?? [])
            .filter { ($0.seasonNumber ?? 0) >= 0 }
            .map {
                PXSeasonInfo(
                    seasonNumber: $0.seasonNumber ?? 0,
                    name: $0.name,
                    overview: $0.overview,
                    posterPath: $0.posterPath,
                    airDate: $0.airDate,
                    episodeCount: $0.episodeCount
                )
            }
            .sorted { $0.seasonNumber < $1.seasonNumber }
        let date = dto.releaseDate ?? dto.firstAirDate
        let year = PXFormat.date(date).map { Calendar.current.component(.year, from: $0) }
        let runtime = dto.runtime ?? dto.episodeRunTime?.first(where: { $0 > 0 })
        let rating = dto.voteAverage.flatMap { $0 > 0 ? $0 : nil }
        let recommended = ((dto.recommendations?.results ?? []) + (dto.similar?.results ?? []))
            .compactMap { recommendation(from: $0, fallback: kind) }
            .reduce(into: [Int: PXMediaRecommendation]()) { result, item in result[item.tmdbID] = item }
            .values
            .sorted { ($0.rating ?? 0) > ($1.rating ?? 0) }
            .prefix(12)
        return PXMediaMetadata(
            tmdbID: dto.id,
            mediaType: kind,
            title: title,
            originalTitle: dto.originalTitle ?? dto.originalName,
            overview: dto.overview,
            tagline: dto.tagline,
            year: year,
            runtimeMinutes: runtime,
            rating: rating,
            voteCount: dto.voteCount,
            popularity: dto.popularity,
            genres: genres,
            posterPath: dto.posterPath,
            backdropPath: dto.backdropPath,
            logoPath: logo,
            contentRating: contentRating(dto, isMovie: kind == .movie),
            status: dto.status,
            originalLanguage: dto.originalLanguage,
            imdbID: dto.externalIds?.imdbId,
            tvdbID: dto.externalIds?.tvdbId,
            cast: Array(cast),
            crew: Array(crew),
            seasons: seasons,
            videos: videos(dto.videos),
            recommendations: Array(recommended),
            homepage: dto.homepage,
            fetchedAt: Date(),
            language: language
        )
    }

    static func season(from dto: PXTMDbSeasonDetail, fallbackNumber: Int) -> PXSeasonInfo {
        PXSeasonInfo(
            seasonNumber: dto.seasonNumber ?? fallbackNumber,
            name: dto.name,
            overview: dto.overview,
            posterPath: dto.posterPath,
            airDate: dto.airDate,
            episodeCount: dto.episodes?.count,
            episodes: (dto.episodes ?? []).map {
                PXEpisodeInfo(
                    seasonNumber: $0.seasonNumber ?? dto.seasonNumber ?? fallbackNumber,
                    episodeNumber: $0.episodeNumber ?? 0,
                    name: $0.name,
                    overview: $0.overview,
                    stillPath: $0.stillPath,
                    airDate: $0.airDate,
                    runtimeMinutes: $0.runtime,
                    rating: $0.voteAverage
                )
            }
            .filter { $0.episodeNumber > 0 }
            .sorted { $0.episodeNumber < $1.episodeNumber }
        )
    }

    static func recommendation(from dto: PXTMDbRecommendationDTO, fallback: PXMediaKind) -> PXMediaRecommendation? {
        let title = dto.title ?? dto.name ?? ""
        guard !title.isEmpty else { return nil }
        let kind: PXMediaKind = dto.mediaType == "movie" ? .movie : (fallback == .anime ? .anime : .series)
        let date = dto.releaseDate ?? dto.firstAirDate
        let year = PXFormat.date(date).map { Calendar.current.component(.year, from: $0) }
        return PXMediaRecommendation(
            tmdbID: dto.id,
            mediaType: kind,
            title: title,
            overview: dto.overview,
            posterPath: dto.posterPath,
            backdropPath: dto.backdropPath,
            year: year,
            rating: dto.voteAverage
        )
    }

    static func genresForAnimeIDs() -> [Int] { [16] }

    private static func chooseLogo(_ logos: [PXTMDbImage]?, language: String) -> String? {
        guard let logos, !logos.isEmpty else { return nil }
        let preferred = language.split(separator: "-").first.map(String.init) ?? language
        return logos.first { $0.iso6391 == preferred }?.filePath
            ?? logos.first { $0.iso6391 == "zh" }?.filePath
            ?? logos.first { $0.iso6391 == "en" }?.filePath
            ?? logos.first { $0.iso6391 == nil }?.filePath
            ?? logos.first?.filePath
    }

    private static func contentRating(_ dto: PXTMDbDetailDTO, isMovie: Bool) -> String? {
        if let ratings = dto.contentRatings?.results {
            let order = ["CN", "US", "JP", "GB"]
            for code in order {
                if let rating = ratings.first(where: { $0.iso31661 == code })?.rating, !rating.isEmpty {
                    return rating
                }
            }
        }
        if isMovie, let results = dto.releaseDates?.results {
            let order = ["CN", "US", "JP", "GB"]
            for code in order {
                if let value = results.first(where: { $0.iso31661 == code })?
                    .releaseDates?.compactMap(\.certification).first(where: { !$0.isEmpty }) {
                    return value
                }
            }
        }
        return nil
    }

    private static func videos(_ videos: PXTMDbVideos?) -> [PXVideoClip] {
        (videos?.results ?? [])
            .filter { ($0.site ?? "").lowercased() == "youtube" }
            .filter { ["Trailer", "Teaser", "Clip"].contains($0.type ?? "") }
            .compactMap { item in
                guard let key = item.key else { return nil }
                return PXVideoClip(
                    key: key,
                    name: item.name ?? "预告片",
                    site: item.site ?? "YouTube",
                    type: item.type ?? "Trailer"
                )
            }
            .prefix(6)
            .map { $0 }
    }

    private static func localizedJob(_ job: String?) -> String? {
        switch job {
        case "Director": "导演"
        case "Creator": "创作者"
        case "Writer": "编剧"
        case "Screenplay": "编剧"
        case "Producer": "制片人"
        default: job
        }
    }
}
