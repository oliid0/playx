import SwiftUI

struct PXTVDetailView: View {
    @EnvironmentObject private var app: PXTVAppState
    let media: PXTVMedia
    @State private var showStreamEntry = false
    @State private var selectedSeason = 1

    private var metadata: PXMediaMetadata? { app.detail }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 30) {
                hero
                if let metadata {
                    actions(metadata)
                    overview(metadata)
                    if !metadata.seasons.isEmpty {
                        episodeSection(metadata)
                    }
                    if !metadata.cast.isEmpty {
                        castSection(metadata)
                    }
                } else if app.detailLoading {
                    PXTVLoadingView(text: "正在加载详情")
                } else {
                    PXTVEmptyView(title: "详情加载失败", message: "检查网络或 TMDB Token。", symbol: "exclamationmark.triangle")
                }
            }
            .padding(.horizontal, 56)
            .padding(.top, 38)
            .padding(.bottom, 70)
        }
        .task { await app.loadDetail(media) }
        .sheet(isPresented: $showStreamEntry) {
            PXTVStreamEntryView(title: metadata?.title ?? media.title)
                .environmentObject(app)
        }
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            PXRemoteImage(url: metadata?.backdropURL ?? media.backdropURL, maxPixel: 2200)
                .frame(maxWidth: .infinity).frame(height: 430).clipped()
            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.10), location: 0),
                    .init(color: PXTheme.background.opacity(0.76), location: 0.66),
                    .init(color: PXTheme.background, location: 1),
                ],
                startPoint: .top, endPoint: .bottom
            )
            HStack(alignment: .bottom, spacing: 24) {
                PXRemoteImage(url: metadata?.posterURL ?? media.posterURL, maxPixel: 600)
                    .frame(width: 170, height: 255)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(PXTheme.stroke))
                VStack(alignment: .leading, spacing: 10) {
                    Text(metadata?.title ?? media.title)
                        .font(PXFont.display(44))
                        .foregroundStyle(PXTheme.textPrimary)
                        .lineLimit(2)
                    if let original = metadata?.originalTitle ?? media.originalTitle, original != (metadata?.title ?? media.title) {
                        Text(original).font(.title3).foregroundStyle(PXTheme.textTertiary)
                    }
                    HStack(spacing: 8) {
                        PXRatingBadge(rating: metadata?.rating ?? media.rating)
                        if let year = metadata?.yearText ?? media.yearText { PXTag(text: year) }
                        if let runtime = metadata?.runtimeText { PXTag(text: runtime) }
                        if let rating = metadata?.contentRating { PXTag(text: rating, tint: PXTheme.warning) }
                    }
                    if let genres = metadata?.genreText, !genres.isEmpty {
                        Text(genres).font(.body).foregroundStyle(PXTheme.textSecondary)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 24)
        }
        .frame(height: 430)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(PXTheme.stroke))
    }

    private func actions(_ metadata: PXMediaMetadata) -> some View {
        HStack(spacing: 14) {
            Button { showStreamEntry = true } label: {
                Label("播放（直链）", systemImage: "play.fill")
            }
            .buttonStyle(PXTVPrimaryButtonStyle())
            Button {
                app.searchQuery = metadata.title
                app.select(.moviePilot)
            } label: {
                Label("MoviePilot 找片", systemImage: "paperplane")
            }
            .buttonStyle(.card)
            Button {
                app.searchQuery = metadata.title
                app.select(.search)
                Task { await app.search() }
            } label: {
                Label("搜索其他版本", systemImage: "magnifyingglass")
            }
            .buttonStyle(.card)
        }
    }

    private func overview(_ metadata: PXMediaMetadata) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("简介").font(PXFont.title(26)).foregroundStyle(PXTheme.textPrimary)
            Text(metadata.overview ?? "暂无简介")
                .font(.body)
                .foregroundStyle(PXTheme.textSecondary)
                .lineSpacing(5)
                .frame(maxWidth: 1000, alignment: .leading)
            HStack(spacing: 30) {
                info("TMDB", "\(metadata.tmdbID)")
                info("状态", metadata.status ?? "—")
                info("语言", metadata.originalLanguage ?? "—")
                info("分级", metadata.contentRating ?? "—")
            }
            .padding(.top, 8)
        }
    }

    private func info(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(PXTheme.textTertiary)
            Text(value).font(.system(size: 16, weight: .semibold)).foregroundStyle(PXTheme.textSecondary)
        }
    }

    private func episodeSection(_ metadata: PXMediaMetadata) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("剧集").font(PXFont.title(26)).foregroundStyle(PXTheme.textPrimary)
                Spacer()
                if metadata.seasons.count > 1 {
                    Menu("第 \(selectedSeason) 季") {
                        ForEach(metadata.seasons) { season in
                            Button(season.displayName) { selectedSeason = season.seasonNumber }
                        }
                    }
                }
            }
            let season = metadata.seasons.first { $0.seasonNumber == selectedSeason } ?? metadata.seasons.first
            if let episodes = season?.episodes, !episodes.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 16)], spacing: 16) {
                    ForEach(episodes) { episode in
                        HStack(spacing: 12) {
                            PXRemoteImage(url: episode.stillURL, maxPixel: 500)
                                .frame(width: 150, height: 84).clipShape(RoundedRectangle(cornerRadius: 8))
                            VStack(alignment: .leading, spacing: 3) {
                                Text("第 \(episode.episodeNumber) 集").font(.caption).foregroundStyle(PXTheme.accent)
                                Text(episode.displayName).font(.system(size: 16, weight: .semibold)).foregroundStyle(PXTheme.textPrimary).lineLimit(1)
                                if let overview = episode.overview, !overview.isEmpty {
                                    Text(overview).font(.caption2).foregroundStyle(PXTheme.textTertiary).lineLimit(2)
                                }
                            }
                            Spacer()
                        }
                        .padding(10)
                        .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 10))
                    }
                }
            } else {
                Text("分集资料将在 TMDB 有数据时显示。")
                    .font(.caption).foregroundStyle(PXTheme.textTertiary)
            }
        }
    }

    private func castSection(_ metadata: PXMediaMetadata) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("演员").font(PXFont.title(26)).foregroundStyle(PXTheme.textPrimary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 20) {
                    ForEach(metadata.cast.prefix(20)) { member in
                        VStack(spacing: 8) {
                            PXRemoteImage(url: member.profileURL, maxPixel: 400)
                                .frame(width: 140, height: 180).clipShape(RoundedRectangle(cornerRadius: 10))
                            Text(member.name).font(.system(size: 16, weight: .semibold)).foregroundStyle(PXTheme.textPrimary).lineLimit(1)
                            Text(member.roleText).font(.caption).foregroundStyle(PXTheme.textTertiary).lineLimit(1)
                        }
                        .frame(width: 140)
                    }
                }
            }
        }
    }
}
