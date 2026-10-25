import SwiftUI
import AVFoundation

struct PXPlayerScreen: View {
    @EnvironmentObject private var app: PXAppState
    @StateObject private var model: PXPlayerModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var showSettings = false
    @State private var showEpisodes = false
    @State private var showInfo = false

    init(request: PXPlaybackRequest) {
        _model = StateObject(wrappedValue: PXPlayerModel(request: request))
    }

    private var storiesLayout: Bool {
        #if os(iOS)
        return model.isPortraitVideo && PXPlayerPreferences.shared.portraitStories && verticalSizeClass != .compact
        #else
        return model.isPortraitVideo && PXPlayerPreferences.shared.portraitStories
        #endif
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let engine = model.engine {
                engine.makeSurface()
                    .id(model.engineKind)
                    .ignoresSafeArea()
            }
            PXDanmakuOverlay(
                coordinator: model.danmaku,
                currentTime: model.currentTime,
                isEnabled: model.isDanmakuEnabled
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            if storiesLayout {
                PXStoriesTapZones(
                    onPrevious: model.playPrevious,
                    onNext: model.playNext,
                    onToggleControls: {
                        if model.controlsVisible { model.hideControls() } else { model.revealsControls() }
                    },
                    enabled: model.controlsVisible == false
                )
            } else {
                PXPlayerGestureLayer(model: model)
            }

            if model.controlsVisible, model.snapshot.state != .failed("") {
                if storiesLayout {
                    PXStoriesHUD(
                        model: model,
                        onClose: close,
                        onEpisodes: { showEpisodes = true },
                        onSettings: { showSettings = true },
                        onInfo: { showInfo = true }
                    )
                    .transition(.opacity)
                } else {
                    PXLandscapeHUD(
                        model: model,
                        onClose: close,
                        onEpisodes: { showEpisodes = true },
                        onSettings: { showSettings = true },
                        onInfo: { showInfo = true }
                    )
                    .transition(.opacity)
                }
            }

            if model.isLocked {
                PXUnlockButton(model: model)
            }

            if model.showsNextPrompt {
                PXNextUpOverlay(model: model)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if model.isResolving {
                PXPlayerLoadingOverlay(text: "正在解析播放地址")
            } else if model.snapshot.state == .opening || model.snapshot.state == .buffering {
                PXPlayerLoadingOverlay(text: model.snapshot.state.title)
            }

            if case .failed(let message) = model.snapshot.state {
                PXPlayerErrorOverlay(message: message, retry: model.retry, close: close)
            }

            if let notice = model.notice {
                VStack {
                    PXToast(message: notice)
                        .padding(.top, 58)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .task(id: notice) {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    if !Task.isCancelled { model.notice = nil }
                }
            }
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
        .pxPlayerSystemChrome()
        .onAppear { model.start() }
        .onDisappear { model.stop() }
        .onChange(of: scenePhase) { model.handleScenePhase($0) }
        .onReceive(NotificationCenter.default.publisher(for: .playerXTogglePlayback)) { _ in model.togglePlayPause() }
        .onReceive(NotificationCenter.default.publisher(for: .playerXSkipBackward)) { _ in model.skipBackward() }
        .onReceive(NotificationCenter.default.publisher(for: .playerXSkipForward)) { _ in model.skipForward() }
        .onReceive(NotificationCenter.default.publisher(for: .playerXPlayNext)) { _ in model.playNext() }
        .onReceive(NotificationCenter.default.publisher(for: .playerXClosePlayer)) { _ in close() }
        .sheet(isPresented: $showSettings) {
            PXPlayerSettingsSheet(model: model)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showEpisodes) {
            PXEpisodeDrawer(model: model)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showInfo) {
            PXPlayerInfoSheet(model: model)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private func close() {
        model.stop()
        app.dismissPlayer()
    }
}

struct PXUnlockButton: View {
    @ObservedObject var model: PXPlayerModel

    var body: some View {
        VStack {
            Spacer()
            Button {
                model.toggleLock()
            } label: {
                Label("解锁控制", systemImage: "lock.open")
            }
            .buttonStyle(PXSecondaryButtonStyle(compact: true))
            .padding(.bottom, 34)
        }
    }
}

struct PXPlayerLoadingOverlay: View {
    var text: String
    var body: some View {
        VStack(spacing: 10) {
            ProgressView().controlSize(.large).tint(.white)
            Text(text).font(.system(size: 11, weight: .medium)).foregroundStyle(.white.opacity(0.62))
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .allowsHitTesting(false)
    }
}
