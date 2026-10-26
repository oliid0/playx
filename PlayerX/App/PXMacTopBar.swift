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
        HStack(spacing: 14) {
            HStack(spacing: 9) {
                PXLogoMark(size: 30)
                Text("PlayerX")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(PXTheme.textPrimary)
            }
            Spacer(minLength: 18)
            HStack(spacing: 4) {
                ForEach(tabs) { tab in
                    Button {
                        app.selectTab(tab)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: tab.symbol).font(.system(size: 11, weight: .semibold))
                            Text(tab.title).font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(app.selectedTab == tab ? PXTheme.textPrimary : PXTheme.textSecondary)
                        .padding(.horizontal, 12)
                        .frame(height: 32)
                        .background(
                            app.selectedTab == tab ? PXTheme.surfaceStrong : .clear,
                            in: Capsule()
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(PXTheme.stroke, lineWidth: 0.7))
            Spacer(minLength: 18)
            Button {
                app.selectTab(.search)
            } label: {
                Image(systemName: PXTab.search.symbol)
            }
            .buttonStyle(PXIconButtonStyle(size: 32))
            .foregroundStyle(app.selectedTab == .search ? PXTheme.accent : PXTheme.textPrimary)
            .accessibilityLabel("搜索全部媒体库")
        }
        .padding(.horizontal, 22)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .frame(maxWidth: 1_100)
        .frame(maxWidth: .infinity)
        .background(PXTheme.background.opacity(0.72))
    }
}
#endif
