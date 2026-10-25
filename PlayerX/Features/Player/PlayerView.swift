import SwiftUI
import Combine
import Foundation

/// 全屏播放器。视频由 `PlayerLayerView`（原生 AVPlayerLayer）渲染，控制层是 `PlayerHUD`。
///
/// 交互约定：
/// - 点画面空白处显示/隐藏 HUD；播放中 4 秒自动隐藏；
/// - 暂停时 HUD 常驻；
/// - 播放结束显示下一集卡片：开启自动连播时 5 秒倒计时，否则等用户点；
/// - 进入后台时尝试启动系统画中画（`scenePhase == .background`）。
struct PlayerView: View {
    @StateObject private var model: PlayerModel
    @ObservedObject private var preferences = PlaybackPreferences.shared
    #if os(iOS)
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    #endif
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @State private var controlsVisible = true
    @State private var hideControlsTask: Task<Void, Never>?
    @State private var showingEpisodes = false
    @State private var showingInfo = false
    @State private var dragSeekStart: Double?
    @State private var dragSeekTarget: Double?
    @State private var dragSeekDelta: Double = 0

    init(drama: Drama, chapters: [Chapter], provider: ContentProvider, request: PlaybackRequest) {
        _model = StateObject(wrappedValue: PlayerModel(
            drama: drama,
            chapters: chapters,
            provider: provider,
            request: request
        ))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            PlayerLayerView(player: model.player) { layer in
                model.attach(playerLayer: layer)
            }
            .ignoresSafeArea()

            if let danmaku = model.danmakuController {
                DanmakuOverlay(controller: danmaku)
                    .ignoresSafeArea()
            }

            gestureLayer

            if model.isBuffering && !model.isLoading {
                bufferingBadge
            }

            if controlsVisible && model.errorMessage == nil {
                if usesPortraitLayout {
                    PlayerPortraitHUD(
                        model: model,
                        onClose: close,
                        onEpisodes: { showingEpisodes = true },
                        onInfo: { showingInfo = true },
                        onInteraction: revealControls
                    )
                    .transition(.opacity)
                    .allowsHitTesting(true)
                } else {
                    PlayerHUD(
                        model: model,
                        onClose: close,
                        onEpisodes: { showingEpisodes = true },
                        onInfo: { showingInfo = true },
                        onInteraction: revealControls
                    )
                    .transition(.opacity)
                    .allowsHitTesting(true)
                }
            }

            if model.showsNextPrompt && model.errorMessage == nil {
                nextEpisodePrompt
                    .padding(.bottom, controlsVisible ? 104 : 38)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if let target = dragSeekTarget {
                seekPreview(target: target, delta: dragSeekDelta)
                    .transition(.opacity.combined(with: .scale(scale: 0.94)))
            }

            if model.isLoading {
                loadingOverlay
            }

            if let message = model.errorMessage {
                errorOverlay(message)
            }

            if let notice = model.noticeMessage {
                toast(notice)
                    .padding(.top, 70)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(Color.black)
        .appPlayerSystemChrome()
        .preferredColorScheme(.dark)
        .appMotion(AppTheme.standard, value: controlsVisible)
        .appMotion(AppTheme.standard, value: model.showsNextPrompt)
        .appMotion(AppTheme.standard, value: model.noticeMessage)
        .onAppear {
            model.start()
            revealControls()
        }
        .onDisappear {
            hideControlsTask?.cancel()
            model.stop()
        }
        .onChange(of: model.isPlaying) { playing in
            if playing {
                scheduleHide()
            } else {
                hideControlsTask?.cancel()
                withAnimation(AppTheme.standard) { controlsVisible = true }
            }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .background, preferences.autoPiP {
                model.startPiPIfPossible()
            }
        }
        .onChange(of: preferences.hudAutoHide) { _ in
            if preferences.hudAutoHide <= 0 {
                hideControlsTask?.cancel()
                withAnimation(AppTheme.standard) { controlsVisible = true }
            } else if model.isPlaying {
                scheduleHide()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .playerXTogglePlayback)) { _ in
            model.togglePlayPause()
            revealControls()
        }
        .onReceive(NotificationCenter.default.publisher(for: .playerXSkipBackward)) { _ in
            model.skipBackward()
            revealControls()
        }
        .onReceive(NotificationCenter.default.publisher(for: .playerXSkipForward)) { _ in
            model.skipForward()
            revealControls()
        }
        .onReceive(NotificationCenter.default.publisher(for: .playerXPlayNext)) { _ in
            model.playNext()
            revealControls()
        }
        .onReceive(NotificationCenter.default.publisher(for: .playerXClosePlayer)) { _ in
            close()
        }
        .sheet(isPresented: $showingEpisodes) {
            PlayerEpisodeSheet(model: model)
                .appPlayerEpisodesSheet()
        }
        .sheet(isPresented: $showingInfo) {
            PlayerInfoSheet(model: model)
                .appPlayerInfoSheet()
        }
    }

    // MARK: - 交互层

    private var usesPortraitLayout: Bool {
        #if os(iOS)
        model.isPortraitVideo && verticalSizeClass != .compact
        #else
        model.isPortraitVideo
        #endif
    }

    private var gestureLayer: some View {
        GeometryReader { proxy in
            Color.black.opacity(0.0001)
                .contentShape(Rectangle())
                .onTapGesture {
                    if controlsVisible {
                        hideControlsTask?.cancel()
                        withAnimation(AppTheme.standard) { controlsVisible = false }
                    } else {
                        revealControls()
                    }
                }
                .gesture(seekDragGesture(in: proxy.size))
        }
        .ignoresSafeArea()
        .accessibilityLabel("显示或隐藏播放控件")
    }

    private func seekDragGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 24)
            .onChanged { value in
                guard preferences.dragSeekEnabled, model.duration > 0 else { return }
                guard abs(value.translation.width) > abs(value.translation.height) * 1.2 else { return }
                if dragSeekStart == nil {
                    dragSeekStart = model.currentTime
                    hideControlsTask?.cancel()
                    withAnimation(AppTheme.quick) { controlsVisible = true }
                }
                let range = min(max(model.duration, 60), 600)
                let delta = Double(value.translation.width / max(size.width, 1)) * range
                dragSeekDelta = delta
                dragSeekTarget = min(max((dragSeekStart ?? 0) + delta, 0), max(model.duration - 0.2, 0))
            }
            .onEnded { value in
                if abs(value.translation.height) > 84,
                   abs(value.translation.height) > abs(value.translation.width) * 1.4 {
                    Haptics.medium()
                    if value.translation.height < 0 {
                        model.playNext()
                    } else {
                        model.playPrevious()
                    }
                    dragSeekStart = nil
                    dragSeekTarget = nil
                    dragSeekDelta = 0
                    revealControls()
                    return
                }

                if let target = dragSeekTarget {
                    Haptics.medium()
                    model.seek(to: target)
                }
                dragSeekStart = nil
                dragSeekTarget = nil
                dragSeekDelta = 0
                revealControls()
            }
    }

    private func seekPreview(target: Double, delta: Double) -> some View {
        VStack {
            Spacer()
            HStack(spacing: 8) {
                Image(systemName: delta >= 0 ? "goforward" : "gobackward")
                    .font(.system(size: 13, weight: .bold))
                Text(AppFormat.time(target))
                    .font(.appMono(13))
                Text(String(format: "%+.0f 秒", delta))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.56))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .frame(height: 42)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.16), lineWidth: 0.8))
            .padding(.bottom, 118)
        }
        .allowsHitTesting(false)
    }

    private func revealControls() {
        withAnimation(AppTheme.standard) { controlsVisible = true }
        scheduleHide()
    }

    private func scheduleHide() {
        hideControlsTask?.cancel()
        let seconds = preferences.hudAutoHide
        guard model.isPlaying, seconds > 0 else { return }
        hideControlsTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            guard !Task.isCancelled else { return }
            withAnimation(AppTheme.standard) { controlsVisible = false }
        }
    }

    private func close() {
        model.stop()
        dismiss()
    }

    // MARK: - 状态层

    private var loadingOverlay: some View {
        VStack(spacing: 10) {
            ProgressView()
                .controlSize(.large)
                .tint(.white)
            Text("正在加载")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.8)
        }
        .allowsHitTesting(false)
    }

    private var bufferingBadge: some View {
        VStack {
            HStack(spacing: 6) {
                ProgressView()
                    .controlSize(.small)
                    .tint(.white)
                Text("缓冲中")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.66))
            }
            .padding(.horizontal, 12)
            .frame(height: 30)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.14), lineWidth: 0.7))
            .padding(.top, 74)
            Spacer()
        }
        .allowsHitTesting(false)
    }

    private func errorOverlay(_ message: String) -> some View {
        ZStack {
            Color.black.opacity(0.72).ignoresSafeArea()
            VStack(spacing: 14) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(AppTheme.warning)
                Text("播放失败")
                    .font(.appTitle(20))
                    .foregroundStyle(.white)
                Text(message)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 28)
                HStack(spacing: 10) {
                    Button("重试") {
                        model.retry()
                        revealControls()
                    }
                    .buttonStyle(BrandActionButtonStyle(compact: true))
                    Button("返回") { close() }
                        .buttonStyle(SecondaryActionButtonStyle(compact: true))
                }
                .padding(.top, 4)
            }
            .padding(24)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.14), lineWidth: 0.8)
            }
            .padding(.horizontal, 28)
        }
    }

    private var nextEpisodePrompt: some View {
        VStack {
            Spacer()
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(AppTheme.brand.opacity(0.18))
                        .frame(width: 40, height: 40)
                    Image(systemName: "play.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppTheme.brandSoft)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(model.hasNextEpisode ? "即将播放第 \(model.currentIndex + 2) 集" : "已是最后一集")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                    Text(model.nextCountdown > 0
                         ? "\(model.nextCountdown) 秒后自动播放"
                         : (model.hasNextEpisode ? "点按播放下一集" : "感谢观看"))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.55))
                }

                Spacer(minLength: 4)

                if model.hasNextEpisode {
                    Button {
                        model.cancelNextPrompt()
                        model.playNext()
                    } label: {
                        Text("下一集")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(AppTheme.onBrand)
                            .padding(.horizontal, 12)
                            .frame(height: 32)
                            .background(AppTheme.brandGradient, in: Capsule())
                    }
                    .buttonStyle(AppPressStyle())
                }

                Button {
                    model.cancelNextPrompt()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.55))
                        .frame(width: 30, height: 30)
                        .background(Color.white.opacity(0.08), in: Circle())
                }
                .buttonStyle(AppPressStyle())
                .accessibilityLabel("取消下一集")
            }
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.14), lineWidth: 0.8)
            }
            .shadow(color: .black.opacity(0.35), radius: 20, y: 8)
            .padding(.horizontal, 20)
        }
    }

    private func toast(_ text: String) -> some View {
        VStack {
            Text(text)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.14), lineWidth: 0.7))
                .task(id: text) {
                    try? await Task.sleep(nanoseconds: 2_800_000_000)
                    if !Task.isCancelled {
                        model.noticeMessage = nil
                    }
                }
            Spacer()
        }
        .allowsHitTesting(false)
    }
}
