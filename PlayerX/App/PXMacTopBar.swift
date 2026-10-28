import SwiftUI

#if os(macOS)
/// OcPlayer 风格的 macOS 顶部胶囊：分区在药丸里，右侧搜索。
struct PXMacTopBar: View {
    @EnvironmentObject private var app: PXAppState
    @ObservedObject private var settings = PXAppSettings.shared

    private var tabs: [PXTab] {
        var values: [PXTab] = [.home]
        if settings.moviePilotEnabled { values.append(.moviePilot) }
        if settings.bangumiEnabled { values.append(.bangumi) }
        values.append(.settings)
        return values
    }

    var body: some View {
        HStack(spacing: 12) {
            if app.canNavigateBack {
                Button {
                    NotificationCenter.default.post(name: .playerXNavigationBack, object: nil)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .bold))
                        .frame(width: 30, height: 30)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(PXTheme.textPrimary)
            }
            HStack(spacing: 9) {
                PXLogoMark(size: 30)
                VStack(alignment: .leading, spacing: 0) {
                    Text(app.pageTitle ?? "PLAYERX")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .kerning(0.8)
                        .foregroundStyle(PXTheme.textPrimary)
                    Text(app.canNavigateBack ? "PLAYERX" : app.selectedTab.title)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(PXTheme.textTertiary)
                }
            }
            .frame(minWidth: 128, alignment: .leading)

            HStack(spacing: 3) {
                ForEach(tabs) { tab in
                    Button {
                        app.selectTab(tab)
                    } label: {
                        HStack(spacing: 6) {
                            tabIcon(tab)
                            Text(tab.title).font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(app.selectedTab == tab ? PXTheme.textPrimary : PXTheme.textSecondary)
                        .padding(.horizontal, 12)
                        .frame(height: 31)
                        .background(
                            app.selectedTab == tab ? PXTheme.surfaceStrong : .clear,
                            in: Capsule()
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(PXTheme.stroke, lineWidth: 0.7))
            .fixedSize()

            Spacer(minLength: 16)

            HStack(spacing: 8) {
                Button {
                    app.selectTab(.search)
                } label: {
                    Image(systemName: PXTab.search.symbol)
                }
                .buttonStyle(PXIconButtonStyle(size: 32))
                .foregroundStyle(app.selectedTab == .search ? PXTheme.accent : PXTheme.textPrimary)
                .accessibilityLabel("搜索全部媒体库")
            }
        }
        .padding(.leading, 88)
        .padding(.trailing, 18)
        .padding(.top, 8)
        .padding(.bottom, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PXWindowDragArea())
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Rectangle().fill(PXTheme.stroke).frame(height: 1)
        }
    }

    @ViewBuilder
    private func tabIcon(_ tab: PXTab) -> some View {
        switch tab {
        case .bangumi:
            Image("bangumi-logo").renderingMode(.template).resizable().scaledToFit().frame(width: 13, height: 13)
        case .moviePilot:
            Image("moviepilot-logo").renderingMode(.template).resizable().scaledToFit().frame(width: 14, height: 12)
        default:
            Image(systemName: tab.symbol).font(.system(size: 11, weight: .semibold))
        }
    }
}
#endif
