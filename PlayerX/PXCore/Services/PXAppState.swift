import Foundation
import SwiftUI
import Combine

enum PXTab: String, CaseIterable, Identifiable, Hashable {
    case home
    case bangumi
    case moviePilot
    case settings
    case search

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "首页"
        case .bangumi: "Bangumi"
        case .moviePilot: "MoviePilot"
        case .settings: "设置"
        case .search: "搜索"
        }
    }

    var symbol: String {
        switch self {
        case .home: "house.fill"
        case .bangumi: "calendar"
        case .moviePilot: "paperplane.fill"
        case .settings: "gearshape.fill"
        case .search: "magnifyingglass"
        }
    }
}

/// 全 App 的单例状态。导航保持轻量：一级分区 + 每个分区的路径由 SwiftUI
/// `NavigationStack` 自己管理；播放器则作为根覆盖层，避免被 navigation bar
/// 或 sheet 裁剪。
@MainActor
final class PXAppState: ObservableObject {
    @Published var selectedSection: PXCatalogSection = .home
    @Published var selectedTab: PXTab = .home
    @Published var searchPresented = false
    @Published var presentedPlayer: PXPlaybackRequest?
    @Published var isShowingSourcePicker = false
    @Published var toast: String?

    @Published var favoritesOnly = false
    @Published var selectedLibrarySection: PXCatalogSection = .movies
    @Published var libraryDestination: PXCatalogSection?

    let catalog = PXCatalogService.shared
    let sourceStore = PXSourceConfigurationStore.shared
    let metadata = PXMetadataCoordinator.shared
    let settings = PXAppSettings.shared
    let playerPreferences = PXPlayerPreferences.shared
    let bangumi = PXBangumiCoordinator.shared
    let moviePilot = PXMoviePilotCoordinator.shared

    private var toastTask: Task<Void, Never>?

    var availableSources: [SourceDescriptor] { catalog.visibleSources }

    func showToast(_ message: String) {
        toast = message
        toastTask?.cancel()
        toastTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_400_000_000)
            guard !Task.isCancelled else { return }
            toast = nil
        }
    }

    func presentPlayer(_ request: PXPlaybackRequest) {
        presentedPlayer = request
    }

    func dismissPlayer() {
        presentedPlayer = nil
    }

    var selectedSectionTitle: String { selectedSection.title }

    func select(_ section: PXCatalogSection) {
        if let kind = section.mediaKind {
            selectedLibrarySection = section
            libraryDestination = section
            selectedSection = .library
            selectedTab = .home
            return
        }
        if section == .library {
            libraryDestination = nil
            selectedSection = .library
            selectedTab = .home
            return
        }
        selectedSection = section
        switch section {
        case .home, .movies, .series, .anime, .shorts, .variety, .documentary, .library:
            selectedTab = .home
        case .bangumi:
            selectedTab = .bangumi
        case .moviepilot:
            selectedTab = .moviePilot
        case .downloads, .profile:
            selectedTab = .settings
        }
    }

    func selectTab(_ tab: PXTab) {
        selectedTab = tab
        switch tab {
        case .home: selectedSection = .home
        case .bangumi: selectedSection = .bangumi
        case .moviePilot: selectedSection = .moviepilot
        case .settings: selectedSection = .profile
        case .search: break
        }
    }

    func handleDeepLink(_ url: URL) {
        guard url.scheme == "playerx" else { return }
        switch url.host {
        case "detail":
            if let source = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "source" })?.value,
               let descriptor = SourceRegistry.descriptor(for: source) {
                selectedSection = .library
                _ = descriptor
            }
        case "player":
            break
        default:
            break
        }
    }
}
