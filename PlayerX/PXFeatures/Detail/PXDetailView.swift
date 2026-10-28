import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct PXDetailView: View {
    @EnvironmentObject private var app: PXAppState
    @StateObject private var model: PXDetailViewModel
    @ObservedObject private var downloads = DownloadStore.shared
    @State private var selectedRecommendation: PXMediaRecommendation?
    @State private var showBangumiSheet = false
    @State private var showMoviePilotSheet = false

    init(entry: PXCatalogEntry, provider: ContentProvider? = nil, resume: HistoryEntry? = nil) {
        _model = StateObject(wrappedValue: PXDetailViewModel(entry: entry, provider: provider, resume: resume))
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    PXDetailHeader(
                        model: model,
                        onPlay: { Task { await model.resume() } },
                        onFollow: { model.toggleFollow() },
                        onDownload: { Task { await model.downloadCurrent() } },
                        onMatch: { model.showMatchSheet = true },
                        onBangumi: { showBangumiSheet = true },
                        onMoviePilot: { showMoviePilotSheet = true },
                        onShare: { share() },
                        height: proxy.size.width > 820 ? 460 : 370
                    )
                    VStack(alignment: .leading, spacing: 24) {
                        PXDetailOverview(model: model, descriptionExpanded: $model.descriptionExpanded)
                        if model.drama.pxKind.isEpisodic || model.chapters.count > 1 {
                            PXDetailEpisodes(model: model) { index in
                                Task { await model.play(index: index) }
                            }
                        }
                        if !model.cast.isEmpty || !model.crew.isEmpty {
                            PXDetailCast(model: model)
                        }
                        PXDetailInfo(model: model)
                        if !model.recommendations.isEmpty {
                            PXDetailRecommendations(model: model) { selectedRecommendation = $0 }
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .refreshable { await model.load() }
        }
        .background(PXPageBackground())
        .navigationTitle(model.title)
        .pxInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                ShareLink(item: model.drama.pxShareURL ?? URL(string: "https://github.com/oliid0/playx")!) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .onAppear { app.enterPage(title: model.title, shareURL: model.drama.pxShareURL) }
        .onDisappear { app.leavePage() }
        .task {
            await model.loadIfNeeded()
            await downloads.refresh()
            downloads.startPolling()
        }
        .onDisappear { downloads.stopPolling() }
        .onChange(of: model.playback?.id) { _ in
            if let request = model.playback {
                app.presentPlayer(request)
                model.playback = nil
            }
        }
        .sheet(isPresented: $model.showMatchSheet) {
            PXTMDbMatchSheet(model: model)
        }
        .sheet(item: $selectedRecommendation) { recommendation in
            PXMediaPreviewSheet(recommendation: recommendation)
        }
        .sheet(isPresented: $showBangumiSheet) {
            PXBangumiLinkSheet(title: model.title)
        }
        .sheet(isPresented: $showMoviePilotSheet) {
            PXMoviePilotQuickSheet(title: model.title, metadata: model.metadata)
        }
        .overlay {
            if model.isResolving {
                ZStack {
                    Color.black.opacity(0.34).ignoresSafeArea()
                    HStack(spacing: 8) {
                        ProgressView().tint(PXTheme.accent)
                        Text("正在解析播放地址")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(PXTheme.textPrimary)
                    }
                    .pxGlassCard(padding: 14)
                }
            }
        }
    }


    private func share() {
        #if os(iOS)
        guard let url = model.drama.pxShareURL else { return }
        let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first,
           let root = scene.keyWindow?.rootViewController {
            root.present(activity, animated: true)
        }
        #else
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(
            model.drama.pxShareURL?.absoluteString ?? model.title,
            forType: .string
        )
        app.showToast("分享链接已复制")
        #endif
    }
}
