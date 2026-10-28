import SwiftUI
import PlayXUI

#if os(macOS)
/// 原生窗口工具栏版本：红绿灯在左，分区图标组紧跟其后，符合 OcPlayer 的 macOS 顶栏。
struct PXMacToolbar: ToolbarContent {
    @ObservedObject var app: PXAppState
    @ObservedObject var settings: PXAppSettings

    private var tabs: [PXTab] {
        var values: [PXTab] = [.home]
        if settings.moviePilotEnabled { values.append(.moviePilot) }
        if settings.bangumiEnabled { values.append(.bangumi) }
        values.append(.settings)
        return values
    }

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            HStack(spacing: 4) {
                ForEach(tabs) { tab in
                    Button { app.selectTab(tab) } label: {
                        tabIcon(tab)
                            .frame(width: 28, height: 24)
                            .contentShape(.rect(cornerRadius: 6))
                            .background(
                                app.selectedTab == tab ? PlayXTheme.surfaceStrong : .clear,
                                in: RoundedRectangle(cornerRadius: 6)
                            )
                    }
                    .buttonStyle(.plain)
                    .help(tab.title)
                    .accessibilityLabel(tab.title)
                }
            }
        }

        ToolbarItem(placement: .principal) {
            Text(app.pageTitle ?? app.selectedTab.title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(PlayXTheme.textPrimary)
                .lineLimit(1)
        }

        ToolbarItemGroup(placement: .primaryAction) {
            if let shareURL = app.pageShareURL {
                ShareLink(item: shareURL) {
                    Image(systemName: "square.and.arrow.up")
                }
                .help("分享")
            }
            Button { app.selectTab(.search) } label: {
                Image(systemName: "magnifyingglass")
            }
            .foregroundStyle(app.selectedTab == .search ? PlayXTheme.accent : PlayXTheme.textPrimary)
            .help("搜索全部媒体库")
        }
    }

    @ViewBuilder
    private func tabIcon(_ tab: PXTab) -> some View {
        switch tab {
        case .home:
            Image(systemName: "house.fill").font(.system(size: 13, weight: .semibold))
        case .moviePilot:
            Image("moviepilot-logo").renderingMode(.template).resizable().scaledToFit().frame(width: 14, height: 13)
        case .bangumi:
            Image("bangumi-logo").renderingMode(.template).resizable().scaledToFit().frame(width: 14, height: 14)
        case .settings:
            Image(systemName: "gearshape").font(.system(size: 13, weight: .semibold))
        case .search:
            Image(systemName: "magnifyingglass").font(.system(size: 13, weight: .semibold))
        }
    }
}
#endif
