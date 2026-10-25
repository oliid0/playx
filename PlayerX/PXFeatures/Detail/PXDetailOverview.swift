import SwiftUI

struct PXDetailOverview: View {
    @ObservedObject var model: PXDetailViewModel
    @Binding var descriptionExpanded: Bool
    var onSelectRecommendation: (PXMediaRecommendation) -> Void
    var onPlayEpisode: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .top, spacing: 14) {
                PXRemoteImage(url: model.posterURL, maxPixel: 500)
                    .frame(width: 104, height: 156)
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .strokeBorder(PXTheme.stroke, lineWidth: 0.7)
                    }
                    .shadow(color: .black.opacity(0.35), radius: 16, y: 8)
                VStack(alignment: .leading, spacing: 9) {
                    Text(model.subtitle ?? model.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(PXTheme.textSecondary)
                        .lineLimit(2)
                    if let overview = model.overview, !overview.isEmpty {
                        Text(overview)
                            .font(.system(size: 13))
                            .foregroundStyle(PXTheme.textSecondary)
                            .lineSpacing(4)
                            .lineLimit(descriptionExpanded ? nil : 6)
                        if overview.count > 150 {
                            Button(descriptionExpanded ? "收起" : "展开全部") {
                                withAnimation(PXTheme.standard) { descriptionExpanded.toggle() }
                            }
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(PXTheme.accent)
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, PXTheme.contentPadding)

            facts
            if !model.videos.isEmpty {
                videos
            }
            if !model.cast.isEmpty {
                castRail
            }
            if !model.recommendations.isEmpty {
                recommendations(onSelect: onSelectRecommendation)
            }
        }
    }

    private var facts: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("资料")
                .font(PXFont.section(17))
                .foregroundStyle(PXTheme.textPrimary)
                .padding(.bottom, 10)
            PXInfoRow(title: "原名", value: model.subtitle)
            PXInfoRow(title: "类型", value: model.genres.joined(separator: " / "))
            PXInfoRow(title: "首播", value: model.yearText)
            PXInfoRow(title: "时长", value: model.runtimeText)
            PXInfoRow(title: "分级", value: model.contentRating)
            PXInfoRow(title: "来源", value: model.entry.providerID)
        }
        .pxFlatCard()
        .padding(.horizontal, PXTheme.contentPadding)
    }

    private var videos: some View {
        VStack(alignment: .leading, spacing: 10) {
            PXSectionHeader(title: "预告片", subtitle: nil, symbol: "play.rectangle")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(model.videos) { clip in
                        if let url = clip.youtubeURL {
                            Link(destination: url) {
                                VStack(alignment: .leading, spacing: 5) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10).fill(PXTheme.surface)
                                        Image(systemName: "play.fill")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundStyle(PXTheme.accent)
                                    }
                                    .frame(width: 190, height: 106)
                                    Text(clip.name)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(PXTheme.textSecondary)
                                        .lineLimit(1)
                                        .frame(width: 190, alignment: .leading)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, PXTheme.contentPadding)
    }

    private var castRail: some View {
        VStack(alignment: .leading, spacing: 10) {
            PXSectionHeader(title: "演员", subtitle: "\(model.cast.count) 位", symbol: "person.2")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(model.cast.prefix(20)) { member in
                        PXCastCard(member: member)
                    }
                }
            }
        }
        .padding(.horizontal, PXTheme.contentPadding)
    }

    private func recommendations(onSelect: @escaping (PXMediaRecommendation) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            PXSectionHeader(title: "相关推荐", subtitle: "TMDB 根据类型与关联度推荐", symbol: "sparkles")
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: 12) {
                    ForEach(model.recommendations) { item in
                        Button {
                            onSelect(item)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                PXRemoteImage(url: item.posterURL, maxPixel: 400)
                                    .frame(width: 112, height: 168)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                Text(item.title)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(PXTheme.textPrimary)
                                    .lineLimit(1)
                                    .frame(width: 112, alignment: .leading)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, PXTheme.contentPadding)
    }
}
