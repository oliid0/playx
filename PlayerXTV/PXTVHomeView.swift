import SwiftUI

struct PXTVHomeView: View {
    @EnvironmentObject private var app: PXTVAppState
    @State private var heroIndex = 0

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 38) {
                if app.isLoading {
                    PXTVLoadingView(text: "正在拉取 TMDB 推荐")
                        .frame(height: 460)
                } else if !app.hero.isEmpty {
                    PXTVHeroView(items: app.hero, index: $heroIndex)
                } else {
                    PXTVEmptyView(title: "暂时没有推荐", message: app.errorMessage ?? "检查网络后重试。", symbol: "tv.slash")
                }
                ForEach(app.rails) { rail in
                    PXTVRailView(rail: rail)
                }
            }
            .padding(.horizontal, 56)
            .padding(.top, 46)
            .padding(.bottom, 60)
        }
        .task { await app.loadHomeIfNeeded() }
    }
}

struct PXTVHeroView: View {
    @EnvironmentObject private var app: PXTVAppState
    let items: [PXTVMedia]
    @Binding var index: Int

    var item: PXTVMedia { items.indices.contains(index) ? items[index] : items[0] }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            PXRemoteImage(url: item.backdropURL, maxPixel: 2200)
                .frame(maxWidth: .infinity)
                .frame(height: 460)
                .clipped()
            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.08), location: 0),
                    .init(color: PXTheme.background.opacity(0.66), location: 0.66),
                    .init(color: PXTheme.background, location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            LinearGradient(colors: [PXTheme.background.opacity(0.72), .clear], startPoint: .leading, endPoint: .trailing)
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    PXTag(text: item.kind.title, tint: PXTheme.accent)
                    if let rating = item.rating { PXRatingBadge(rating: rating) }
                    if let year = item.yearText { PXTag(text: year) }
                }
                Text(item.title)
                    .font(PXFont.display(54))
                    .foregroundStyle(PXTheme.textPrimary)
                    .lineLimit(2)
                    .shadow(color: .black.opacity(0.45), radius: 14, y: 6)
                if let overview = item.overview, !overview.isEmpty {
                    Text(overview)
                        .font(.system(size: 18))
                        .foregroundStyle(PXTheme.textSecondary)
                        .lineSpacing(6)
                        .lineLimit(3)
                        .frame(maxWidth: 820, alignment: .leading)
                }
                HStack(spacing: 18) {
                    NavigationLink(value: PXTVRoute.media(item)) {
                        Label("详情", systemImage: "info.circle")
                    }
                    .buttonStyle(PXTVPrimaryButtonStyle())
                    Button {
                        app.path.append(.media(item))
                    } label: {
                        Label("开始播放", systemImage: "play.fill")
                    }
                    .buttonStyle(PXTVPrimaryButtonStyle())
                }
                .padding(.top, 8)
                HStack(spacing: 8) {
                    ForEach(items.indices, id: \.self) { idx in
                        Button {
                            withAnimation(PXTheme.heroMotion) { index = idx }
                        } label: {
                            Capsule()
                                .fill(idx == index ? PXTheme.accent : .white.opacity(0.25))
                                .frame(width: idx == index ? 28 : 8, height: 5)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 6)
            }
            .padding(.horizontal, 56)
            .padding(.bottom, 34)
        }
        .frame(height: 460)
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .overlay(RoundedRectangle(cornerRadius: 26).strokeBorder(PXTheme.stroke, lineWidth: 0.8))
    }
}

struct PXTVRailView: View {
    let rail: PXTVRail

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(rail.title).font(PXFont.title(26)).foregroundStyle(PXTheme.textPrimary)
                    if let subtitle = rail.subtitle { Text(subtitle).font(.caption).foregroundStyle(PXTheme.textTertiary) }
                }
                Spacer()
            }
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: 20) {
                    ForEach(rail.items) { media in
                        NavigationLink(value: PXTVRoute.media(media)) {
                            if rail.style == .landscape {
                                PXTVLandscapeTile(media: media)
                            } else {
                                PXTVPosterTile(media: media)
                            }
                        }
                        .buttonStyle(.card)
                    }
                }
                .padding(.vertical, 18)
                .padding(.horizontal, 20)
            }
            .scrollClipDisabled()
        }
    }
}

struct PXTVPosterTile: View {
    let media: PXTVMedia

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PXRemoteImage(url: media.posterURL, maxPixel: 600)
                .frame(width: 190, height: 285)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 3) {
                Text(media.title).font(.system(size: 18, weight: .semibold)).foregroundStyle(PXTheme.textPrimary).lineLimit(1)
                Text(media.yearText ?? media.kind.title).font(.caption).foregroundStyle(PXTheme.textTertiary)
            }
            .frame(width: 190, alignment: .leading)
        }
        .frame(width: 190)
    }
}

struct PXTVLandscapeTile: View {
    let media: PXTVMedia

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PXRemoteImage(url: media.backdropURL ?? media.posterURL, maxPixel: 900)
                .frame(width: 380, height: 214)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 3) {
                Text(media.title).font(.system(size: 20, weight: .semibold)).foregroundStyle(PXTheme.textPrimary).lineLimit(1)
                Text(media.yearText ?? media.kind.title).font(.caption).foregroundStyle(PXTheme.textTertiary)
            }
            .frame(width: 380, alignment: .leading)
        }
        .frame(width: 380)
    }
}

struct PXTVPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(.black.opacity(0.86))
            .padding(.horizontal, 26)
            .frame(height: 52)
            .background(PXTheme.accent, in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
    }
}

struct PXTVLoadingView: View {
    var text: String
    var body: some View {
        VStack(spacing: 14) {
            ProgressView().controlSize(.large).tint(PXTheme.accent)
            Text(text).font(.caption).foregroundStyle(PXTheme.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PXTVEmptyView: View {
    var title: String
    var message: String
    var symbol: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol).font(.system(size: 46, weight: .light)).foregroundStyle(PXTheme.textTertiary)
            Text(title).font(PXFont.title(24)).foregroundStyle(PXTheme.textPrimary)
            Text(message).font(.body).foregroundStyle(PXTheme.textSecondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(60)
    }
}
