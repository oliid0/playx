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
        VStack(alignment: .leading, spacing: 16) {
            PXDetailBackdrop(
                url: model.metadata?.backdropURL,
                drama: model.drama,
                logoURL: model.logoURL,
                title: model.title,
                height: height
            )
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .bottom, spacing: 12) {
                    if model.logoURL != nil {
                        Text(model.title)
                            .font(PXFont.display(30))
                            .foregroundStyle(PXTheme.textPrimary)
                            .lineLimit(2)
                    }
                    Spacer()
                }
                HStack(spacing: 8) {
                    if let rating = model.rating { PXRatingBadge(rating: rating) }
                    PXMetadataLine(parts: metadataParts)
                    if model.drama.vip == true { PXTag(text: "VIP", tint: PXTheme.accent) }
                }
                if !model.genres.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(model.genres.prefix(8), id: \.self) { genre in
                                PXTag(text: genre, tint: PXTheme.textSecondary)
                            }
                        }
                    }
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
            .padding(.horizontal, PXTheme.contentPadding)
            .padding(.top, -30)
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
