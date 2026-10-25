import SwiftUI

struct PXDetailInfo: View {
    @ObservedObject var model: PXDetailViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 9) {
                Text("媒体信息").font(PXFont.section(17)).foregroundStyle(PXTheme.textPrimary)
                PXInfoRow(title: "站源", value: model.entry.providerID)
                PXInfoRow(title: "条目 ID", value: model.drama.id)
                PXInfoRow(title: "分类", value: model.drama.category)
                PXInfoRow(title: "清晰度", value: model.mediaInfo.quality)
                PXInfoRow(title: "文件大小", value: model.mediaInfo.fileSize)
                PXInfoRow(title: "TMDB", value: model.metadata.map { "\($0.tmdbID)" })
                PXInfoRow(title: "IMDb", value: model.metadata?.imdbID)
                PXInfoRow(title: "原始语言", value: model.metadata?.originalLanguage)
                PXInfoRow(title: "状态", value: model.metadata?.status)
            }
            .pxFlatCard()
            .padding(.horizontal, PXTheme.contentPadding)

            if let metadata = model.metadata {
                VStack(alignment: .leading, spacing: 9) {
                    Text("外部链接").font(PXFont.section(17)).foregroundStyle(PXTheme.textPrimary)
                    ForEach(PXExternalLink.make(
                        imdbID: metadata.imdbID,
                        tmdbID: metadata.tmdbID,
                        mediaType: metadata.mediaType,
                        homepage: metadata.homepage
                    )) { link in
                        Link(destination: link.url) {
                            HStack(spacing: 10) {
                                Image(systemName: link.symbol)
                                    .frame(width: 20)
                                    .foregroundStyle(PXTheme.accent)
                                Text(link.title)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(PXTheme.textPrimary)
                                if let subtitle = link.subtitle {
                                    Text(subtitle)
                                        .font(.system(size: 10))
                                        .foregroundStyle(PXTheme.textTertiary)
                                }
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(PXTheme.textTertiary)
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .pxFlatCard()
                .padding(.horizontal, PXTheme.contentPadding)
            }

            if let location = model.metadata?.homepage, let url = URL(string: location) {
                Link("访问官方网站", destination: url)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(PXTheme.accent)
                    .padding(.horizontal, PXTheme.contentPadding)
            }
        }
    }
}
