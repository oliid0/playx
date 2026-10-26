import SwiftUI

struct PXDetailOverview: View {
    @ObservedObject var model: PXDetailViewModel
    @Binding var descriptionExpanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .top, spacing: 14) {
                Group {
                    if let poster = model.metadata?.posterURL {
                        PXRemoteImage(url: poster, maxPixel: 500)
                    } else {
                        PXCoverImage(drama: model.drama, maxPixel: 500)
                    }
                }
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


}
