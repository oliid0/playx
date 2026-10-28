import SwiftUI

struct PXDetailHeader: View {
    @ObservedObject var model: PXDetailViewModel
    var onPlay: () -> Void
    var onFollow: () -> Void
    var onDownload: () -> Void
    var onMatch: () -> Void
    var onBangumi: () -> Void
    var onMoviePilot: () -> Void
    var onShare: () -> Void
    var height: CGFloat

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            PXDetailBackdrop(
                url: model.metadata?.backdropURL,
                drama: model.drama,
                logoURL: model.logoURL,
                title: model.title,
                height: height,
                showsForeground: false
            )
            HStack(alignment: .top, spacing: 20) {
                poster
                    .frame(width: 148, height: 222)
                    .offset(y: 38)
                VStack(alignment: .leading, spacing: 10) {
                    titleBlock
                    HStack(spacing: 8) {
                        if let rating = model.rating { PXRatingBadge(rating: rating) }
                        PXMetadataLine(parts: metadataParts)
                        if model.drama.vip == true { PXTag(text: "VIP", tint: PXTheme.accent) }
                    }
                    if !model.genres.isEmpty {
                        PXUITagWrap(tags: Array(model.genres.prefix(6)))
                    }
                    HStack(spacing: 9) {
                        Button(action: onPlay) {
                            HStack(spacing: 7) {
                                Image(systemName: "play.fill")
                                Text(model.resumeTitle)
                            }
                            .frame(minWidth: 132)
                        }
                        .buttonStyle(PXPrimaryButtonStyle())
                        .disabled(model.chapters.isEmpty)

                        Button(action: onFollow) {
                            Image(systemName: model.followStatus == nil ? "heart" : "heart.fill")
                                .frame(width: 42, height: 42)
                        }
                        .buttonStyle(PXIconButtonStyle(size: 44))
                        .foregroundStyle(model.followStatus == nil ? PXTheme.textPrimary : PXTheme.rose)

                        if model.provider.sourceKind == .station {
                            Button(action: onDownload) {
                                Image(systemName: "arrow.down.circle")
                                    .frame(width: 42, height: 42)
                            }
                            .buttonStyle(PXIconButtonStyle(size: 44))
                        }

                        Menu {
                            Button { onMatch() } label: { Label("匹配 TMDB 元数据", systemImage: "sparkles.tv") }
                            Button { onBangumi() } label: { Label("在 Bangumi 追番", systemImage: "calendar") }
                            Button { onMoviePilot() } label: { Label("MoviePilot 找片", systemImage: "paperplane") }
                            Divider()
                            Button { onShare() } label: { Label("分享", systemImage: "square.and.arrow.up") }
                        } label: {
                            Image(systemName: "ellipsis")
                                .frame(width: 42, height: 42)
                        }
                        .buttonStyle(PXIconButtonStyle(size: 44))
                    }
                }
                .padding(.top, 54)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, PXTheme.widePadding)
            .frame(maxWidth: 1_100, alignment: .leading)
        }
        .frame(height: height + 30)
    }

    private var poster: some View {
        Group {
            if let url = model.metadata?.posterURL {
                PXRemoteImage(url: url, maxPixel: 500)
            } else {
                PXCoverImage(drama: model.drama, maxPixel: 500)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: PXTheme.posterRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: PXTheme.posterRadius, style: .continuous).strokeBorder(PXTheme.stroke, lineWidth: 0.8))
        .shadow(color: .black.opacity(0.42), radius: 18, y: 10)
    }

    @ViewBuilder
    private var titleBlock: some View {
        if let logoURL = model.logoURL {
            PXRemoteImage(url: logoURL, contentMode: .fit, maxPixel: 900)
                .frame(maxWidth: 300, maxHeight: 78, alignment: .leading)
        } else {
            Text(model.title)
                .font(PXFont.display(34))
                .foregroundStyle(PXTheme.textPrimary)
                .lineLimit(2)
                .shadow(color: .black.opacity(0.42), radius: 12, y: 5)
        }
    }

    private var metadataParts: [String] {
        var parts: [String] = []
        if let year = model.yearText { parts.append(year) }
        if let runtime = model.runtimeText { parts.append(runtime) }
        if let rating = model.contentRating { parts.append(rating) }
        if let count = model.drama.pxEpisodeCount, model.drama.pxKind.isEpisodic { parts.append("\(count) 集") }
        return parts
    }
}
