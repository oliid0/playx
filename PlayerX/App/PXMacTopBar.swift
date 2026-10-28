import SwiftUI
import PlayXUI

#if os(macOS)
/// macOS 顶栏现在完全交给 `PlayXUI.PXShellChrome`，本文件只负责把
/// PlayerX 的分区、页面标题、分享和搜索映射成该模块的回调。
struct PXMacTopBar: View {
    @EnvironmentObject private var app: PXAppState
    @ObservedObject private var settings = PXAppSettings.shared

    private var sections: [PXShellSection] {
        var values: [PXShellSection] = [
            PXShellSection(id: PXTab.home.rawValue, title: PXTab.home.title, icon: .symbol("house.fill"))
        ]
        if settings.moviePilotEnabled {
            values.append(PXShellSection(id: PXTab.moviePilot.rawValue, title: PXTab.moviePilot.title, icon: .brand("moviepilot-logo")))
        }
        if settings.bangumiEnabled {
            values.append(PXShellSection(id: PXTab.bangumi.rawValue, title: PXTab.bangumi.title, icon: .brand("bangumi-logo")))
        }
        values.append(PXShellSection(id: PXTab.settings.rawValue, title: PXTab.settings.title, icon: .symbol("gearshape")))
        return values
    }

    var body: some View {
        PXShellChrome(
            sections: sections,
            selectedID: app.selectedTab.rawValue,
            title: app.pageTitle ?? "PLAYERX",
            subtitle: app.pageTitle == nil ? app.selectedTab.title : "PLAYERX",
            canGoBack: app.canNavigateBack,
            shareURL: app.pageShareURL,
            onSelect: { id in
                if let tab = PXTab(rawValue: id) { app.selectTab(tab) }
            },
            onBack: {
                NotificationCenter.default.post(name: .playerXNavigationBack, object: nil)
            },
            onSearch: { app.selectTab(.search) }
        )
    }
}
#endif
