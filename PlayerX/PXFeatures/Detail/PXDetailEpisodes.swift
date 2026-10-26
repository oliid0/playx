import SwiftUI

struct PXDetailEpisodes: View {
    @ObservedObject var model: PXDetailViewModel
    @ObservedObject private var downloads = DownloadStore.shared
    var onPlay: (Int) -> Void

    private let columns = [GridItem(.adaptive(minimum: 52), spacing: 8)]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            if model.seasons.count > 1 {
                PXSeasonPicker(seasons: model.seasons, selection: Binding(
                    get: { model.selectedSeason },
                    set: { value in Task { await model.selectSeason(value) } }
                ))
                .padding(.horizontal, PXTheme.contentPadding)
            }
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("选集")
                        .font(PXFont.section(17))
                        .foregroundStyle(PXTheme.textPrimary)
                    Text("\(model.chapters.count) 集")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(PXTheme.textTertiary)
                    Spacer()
                    if model.provider.sourceKind == .station {
                        Button {
                            Task { await model.downloadAll() }
                        } label: {
                            Label("缓存全集", systemImage: "arrow.down.circle")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(PXTheme.accent)
                        }
                        .buttonStyle(.plain)
                    }
                }
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(Array(model.chapters.enumerated()), id: \.element.id) { index, chapter in
                        Button {
                            onPlay(index)
                        } label: {
                            VStack(spacing: 3) {
                                Text(String(format: "%02d", index + 1))
                                    .font(PXFont.mono(13))
                                if model.isDownloaded(index) {
                                    Image(systemName: "arrow.down.circle.fill")
                                        .font(.system(size: 7))
                                        .foregroundStyle(PXTheme.mint)
                                } else if model.downloadProgress(index) > 0 {
                                    PXProgressBar(value: model.downloadProgress(index), height: 2)
                                        .frame(width: 24)
                                }
                            }
                            .foregroundStyle(index == model.selectedChapter ? .black.opacity(0.86) : PXTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(index == model.selectedChapter ? PXTheme.accent : PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 9))
                            .overlay {
                                RoundedRectangle(cornerRadius: 9)
                                    .strokeBorder(index == model.selectedChapter ? .clear : PXTheme.stroke, lineWidth: 0.6)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, PXTheme.contentPadding)

            if !model.currentMetadataEpisodes.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    PXSectionHeader(
                        title: "分集简介",
                        subtitle: model.currentSeason?.displayName,
                        symbol: "text.bubble"
                    )
                    ForEach(model.currentMetadataEpisodes) { episode in
                        Button {
                            onPlay(max(0, episode.episodeNumber - 1))
                        } label: {
                            HStack(alignment: .top, spacing: 11) {
                                PXRemoteImage(url: episode.stillURL, maxPixel: 500)
                                    .frame(width: 118, height: 66)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(episode.displayName)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(PXTheme.textPrimary)
                                        .lineLimit(1)
                                    if let overview = episode.overview, !overview.isEmpty {
                                        Text(overview)
                                            .font(.system(size: 10))
                                            .foregroundStyle(PXTheme.textTertiary)
                                            .lineLimit(2)
                                    }
                                    if let date = episode.airDate, !date.isEmpty {
                                        Text(PXFormat.airDate(date))
                                            .font(.system(size: 9))
                                            .foregroundStyle(PXTheme.textTertiary)
                                    }
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(.vertical, 7)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, PXTheme.contentPadding)
            }
        }
    }
}
