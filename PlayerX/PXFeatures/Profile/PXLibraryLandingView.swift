import SwiftUI

struct PXLibraryLandingView: View {
    @EnvironmentObject private var app: PXAppState
    @State private var featured: [PXCatalogEntry] = []
    @State private var loading = true

    var body: some View {
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("片库")
                                .font(PXFont.display(34))
                                .foregroundStyle(PXTheme.textPrimary)
                            Text("电影 · 剧集 · 动漫 · 短剧 · 综艺 · 纪录片")
                                .font(PXFont.caption(11))
                                .foregroundStyle(PXTheme.textTertiary)
                        }
                        Spacer()
                        Button { app.searchPresented = true } label: {
                            Image(systemName: "magnifyingglass")
                        }
                        .buttonStyle(PXIconButtonStyle(size: 38))
                    }
                    .padding(.horizontal, PXTheme.padding(for: proxy.size.width))
                    categoryGrid(width: proxy.size.width)
                    if !featured.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            PXSectionHeader(title: "最近更新", subtitle: "来自启用站源", symbol: "clock.arrow.circlepath")
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(alignment: .top, spacing: 12) {
                                    ForEach(featured) { entry in
                                        NavigationLink { PXDetailView(entry: entry) } label: {
                                            PXPosterCard(entry: entry, width: 132)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, PXTheme.padding(for: proxy.size.width))
                    }
                }
                .padding(.top, PXPlatform.isMac ? 20 : 8)
                .padding(.bottom, 34)
            }
            .refreshable { await load() }
        }
        .background(PXPageBackground())
        .navigationTitle("片库")
        .pxHiddenNavigationBar()
        .task { await load() }
    }

    private func categoryGrid(width: CGFloat) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: width > 760 ? 200 : 156), spacing: 12)], spacing: 12) {
            ForEach(PXCatalogSection.contentSections.filter { $0 != .home }) { section in
                NavigationLink {
                    PXBrowseView(section: section)
                } label: {
                    PXLibraryCategoryCard(section: section)
                }
                .buttonStyle(.plain)
            }
            NavigationLink {
                PXBrowseView(section: .library)
            } label: {
                PXLibraryCategoryCard(section: .library)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, PXTheme.padding(for: width))
    }

    private func load() async {
        loading = true
        let result = await PXCatalogService.shared.items(section: .library)
        featured = Array(result.items.prefix(18))
        loading = false
    }
}

struct PXLibraryCategoryCard: View {
    let section: PXCatalogSection

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [
                    PXTheme.backgroundLift,
                    PXTheme.backgroundDeep,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [PXTheme.accent.opacity(section == .library ? 0.25 : 0.16), .clear],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 180
            )
            Image(systemName: section.symbol)
                .font(.system(size: 76, weight: .black))
                .foregroundStyle(.white.opacity(0.045))
                .offset(x: 70, y: 20)
            VStack(alignment: .leading, spacing: 5) {
                Image(systemName: section.symbol)
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(PXTheme.accent)
                Text(section.title)
                    .font(PXFont.title(18))
                    .foregroundStyle(PXTheme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(PXTheme.textTertiary)
            }
            .padding(15)
        }
        .frame(height: 116)
        .clipShape(RoundedRectangle(cornerRadius: 17))
        .overlay(RoundedRectangle(cornerRadius: 17).strokeBorder(PXTheme.stroke, lineWidth: 0.7))
        .pxHoverLift()
    }

    private var subtitle: String {
        switch section {
        case .movies: "院线 / 经典 / 高分"
        case .series: "国产 / 美剧 / 英剧 / 日韩"
        case .anime: "新番 / 国创 / 剧场版"
        case .shorts: "竖屏故事，一划一集"
        case .variety: "真人秀 / 脱口秀 / 音乐"
        case .documentary: "自然 / 历史 / 人文"
        default: "全部内容，按标签筛选"
        }
    }
}
