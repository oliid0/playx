import SwiftUI

struct PXTVRootView: View {
    @StateObject private var app = PXTVAppState()

    var body: some View {
        NavigationStack(path: $app.path) {
            PXTVShellView()
                .navigationDestination(for: PXTVRoute.self) { route in
                    switch route {
                    case .media(let media):
                        PXTVDetailView(media: media)
                    case .bangumi(let id):
                        PXTVBangumiDetailView(subjectID: id)
                    case .search:
                        PXTVSearchView()
                    case .settings:
                        PXTVSettingsView()
                    case .sources:
                        PXTVSourcesView()
                    case .sourceLibrary(let sourceID):
                        PXTVSourceLibraryView(sourceID: sourceID)
                    case .sourceDetail(let sourceID, let drama):
                        PXTVSourceDetailView(sourceID: sourceID, drama: drama)
                    }
                }
        }
        .environmentObject(app)
        .tint(PXTheme.accent)
        .preferredColorScheme(.dark)
        .fullScreenCover(item: $app.playback) { request in
            PXTVPlayerView(request: request)
        }
    }
}

struct PXTVShellView: View {
    @EnvironmentObject private var app: PXTVAppState
    @FocusState private var focusedTab: PXTVTab?

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            ZStack {
                PXPageBackground()
                content
            }
        }
        .ignoresSafeArea()
        .onAppear { focusedTab = .home }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 9) {
                PXLogoMark(size: 34)
                VStack(alignment: .leading, spacing: 0) {
                    Text("PlayerX").font(.system(size: 15, weight: .heavy, design: .rounded)).foregroundStyle(PXTheme.textPrimary)
                    Text("tvOS").font(.system(size: 8, weight: .medium)).foregroundStyle(PXTheme.textTertiary)
                }
            }
            .padding(.bottom, 16)
            ForEach(PXTVTab.sidebarTabs) { tab in
                Button {
                    app.select(tab)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: tab.symbol).font(.system(size: 16, weight: .semibold)).frame(width: 24)
                        Text(tab.title).font(.system(size: 15, weight: .semibold))
                        Spacer()
                    }
                    .foregroundStyle(app.tab == tab ? PXTheme.accent : PXTheme.textSecondary)
                    .padding(.horizontal, 14)
                    .frame(height: 50)
                    .background(app.tab == tab ? PXTheme.accent.opacity(0.12) : .clear, in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .focused($focusedTab, equals: tab)
            }
            Spacer()
            Text("Pillarbox · TMDB").font(.system(size: 9)).foregroundStyle(PXTheme.textTertiary)
        }
        .padding(.horizontal, 22)
        .padding(.top, 54)
        .padding(.bottom, 40)
        .frame(width: 240)
        .background(PXTheme.backgroundLift.opacity(0.42))
    }

    @ViewBuilder
    private var content: some View {
        switch app.tab {
        case .home:
            PXTVHomeView()
        case .movies, .series, .anime:
            PXTVBrowseView(tab: app.tab)
        case .bangumi:
            PXTVBangumiView()
        case .moviePilot:
            PXTVMoviePilotView()
        case .search:
            PXTVSearchView()
        case .settings:
            PXTVSettingsView()
        }
    }
}
