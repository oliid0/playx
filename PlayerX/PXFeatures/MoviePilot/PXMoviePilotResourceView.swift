import SwiftUI

struct PXMoviePilotResourceView: View {
    let media: PXMoviePilotMedia
    @ObservedObject private var coordinator = PXMoviePilotCoordinator.shared
    @Environment(\.dismiss) private var dismiss
    @State private var filter = ""
    @State private var downloading: Set<String> = []

    private var filtered: [PXMoviePilotTorrent] {
        guard !filter.isEmpty else { return coordinator.torrents }
        return coordinator.torrents.filter {
            ($0.siteName ?? "").localizedCaseInsensitiveContains(filter)
            || $0.title.localizedCaseInsensitiveContains(filter)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    PXRemoteImage(url: media.posterURL, maxPixel: 300)
                        .frame(width: 74, height: 111)
                        .clipShape(RoundedRectangle(cornerRadius: 9))
                    VStack(alignment: .leading, spacing: 5) {
                        Text(media.title).font(PXFont.title(20)).foregroundStyle(PXTheme.textPrimary)
                        PXMetadataLine(parts: [media.year, media.type].compactMap { $0 })
                        if let overview = media.overview {
                            Text(overview).font(.system(size: 10)).foregroundStyle(PXTheme.textTertiary).lineLimit(3)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, PXTheme.contentPadding)

                HStack(spacing: 9) {
                    Button {
                        Task { await coordinator.subscribe(media) }
                    } label: {
                        Label("订阅", systemImage: "bell.badge")
                    }
                    .buttonStyle(PXPrimaryButtonStyle())
                    Button {
                        Task { await coordinator.searchTorrents(for: media) }
                    } label: {
                        Label("重新搜索", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(PXSecondaryButtonStyle(compact: true))
                    Spacer()
                }
                .padding(.horizontal, PXTheme.contentPadding)

                PXSearchField(text: $filter, prompt: "过滤站点 / 标题")
                    .padding(.horizontal, PXTheme.contentPadding)

                if coordinator.isSearchingTorrents {
                    PXLoadingCard()
                } else if filtered.isEmpty {
                    PXEmptyState(title: "没有资源", message: "MoviePilot 没有搜到可用种子，换一个站点或稍后重试。", symbol: "tray")
                } else {
                    VStack(spacing: 8) {
                        ForEach(filtered) { torrent in
                            PXMoviePilotTorrentRow(torrent: torrent) {
                                Task {
                                    downloading.insert(torrent.id)
                                    await coordinator.download(torrent, media: media)
                                    downloading.remove(torrent.id)
                                }
                            }
                            .disabled(downloading.contains(torrent.id))
                        }
                    }
                    .padding(.horizontal, PXTheme.contentPadding)
                }
            }
            .padding(.vertical, 12)
        }
        .background(PXPageBackground())
        .navigationTitle("资源")
        .pxInlineNavigationTitle()
        .task {
            if coordinator.torrents.isEmpty { await coordinator.searchTorrents(for: media) }
        }
    }
}

struct PXMoviePilotQuickSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var coordinator = PXMoviePilotCoordinator.shared
    let title: String
    let metadata: PXMediaMetadata?
    @State private var searchText: String

    init(title: String, metadata: PXMediaMetadata?) {
        self.title = title
        self.metadata = metadata
        _searchText = State(initialValue: title)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 13) {
                    PXSearchField(text: $searchText, prompt: "搜索 MoviePilot 媒体") {
                        Task { await coordinator.searchMedia(searchText) }
                    }
                    if coordinator.isLoading {
                        PXLoadingCard()
                    } else if coordinator.mediaResults.isEmpty {
                        PXEmptyState(title: "没有媒体结果", message: "输入片名后点击键盘搜索。", symbol: "paperplane")
                    } else {
                        ForEach(coordinator.mediaResults) { media in
                            NavigationLink {
                                PXMoviePilotResourceView(media: media)
                            } label: {
                                PXMoviePilotMediaCard(media: media)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(20)
            }
            .background(PXPageBackground())
            .navigationTitle("MoviePilot 找片")
            .pxInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("关闭") { dismiss() } }
            }
            .task {
                guard coordinator.isLoggedIn else { return }
                await coordinator.searchMedia(searchText)
            }
        }
        .preferredColorScheme(.dark)
    }
}
