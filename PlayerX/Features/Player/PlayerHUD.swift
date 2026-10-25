import SwiftUI
import AVKit
import Foundation

/// 播放器 HUD：自绘控制层，浮在原生 `AVPlayerLayer` 上。
/// 视觉上参考 OcPlayer 的玻璃 HUD，但交互保持 iOS 直觉：
/// 中央三个大按钮、底部时间轴 + 倍速/选集/画中画/AirPlay。
struct PlayerHUD: View {
    @ObservedObject var model: PlayerModel
    @ObservedObject private var preferences = PlaybackPreferences.shared

    let onClose: () -> Void
    let onEpisodes: () -> Void
    let onInfo: () -> Void
    let onInteraction: () -> Void

    @State private var isScrubbing = false
    @State private var scrubTime: Double = 0

    private var displayTime: Double {
        isScrubbing ? scrubTime : model.currentTime
    }

    var body: some View {
        ZStack {
            scrim

            VStack(spacing: 0) {
                topBar
                Spacer(minLength: 0)
                transport
                Spacer(minLength: 0)
                bottomBar
            }
            .padding(.horizontal, 18)
            .padding(.top, 6)
            .padding(.bottom, 10)
        }
        .foregroundStyle(.white)
    }

    // MARK: - 顶部

    private var topBar: some View {
        HStack(spacing: 11) {
            glassButton("xmark", size: 38, label: "关闭播放器") {
                onInteraction()
                onClose()
            }

            volumePanel

            Spacer(minLength: 6)

            if model.canToggleDanmaku {
                Button {
                    Haptics.selection()
                    model.toggleDanmaku()
                    onInteraction()
                } label: {
                    Text("弹")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(model.isDanmakuEnabled ? AppTheme.onBrand : .white)
                        .frame(width: 38, height: 38)
                        .background {
                            Circle().fill(model.isDanmakuEnabled ? AnyShapeStyle(AppTheme.brandGradient) : AnyShapeStyle(Material.ultraThinMaterial))
                        }
                        .overlay(Circle().strokeBorder(Color.white.opacity(0.22), lineWidth: 0.8))
                }
                .buttonStyle(AppPressStyle())
                .accessibilityLabel(model.isDanmakuEnabled ? "关闭弹幕" : "开启弹幕")
            }

            Menu {
                if model.qualities.count > 1 {
                    Menu {
                        ForEach(model.qualities, id: \.self) { quality in
                            Button {
                                model.setQuality(quality)
                                onInteraction()
                            } label: {
                                HStack {
                                    Text(qualityName(quality))
                                    if model.selectedQuality == quality {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Label("清晰度 · \(model.qualityLabel)", systemImage: "4k.tv")
                    }
                    Divider()
                }
                if model.hasAudioOptions || model.hasSubtitleOptions {
                    PlayerTrackMenu(model: model, onInteraction: onInteraction)
                    Divider()
                }
                Menu {
                    Button("关闭定时") {
                        model.setSleepTimer(minutes: nil)
                        onInteraction()
                    }
                    ForEach([15, 30, 60], id: \.self) { minutes in
                        Button("\(minutes) 分钟") {
                            model.setSleepTimer(minutes: minutes)
                            onInteraction()
                        }
                    }
                } label: {
                    Label(
                        model.sleepTimerMinutes.map { "定时关闭 · \($0) 分钟" } ?? "定时关闭",
                        systemImage: "moon.zzz"
                    )
                }
                Divider()
                Button {
                    onInfo()
                    onInteraction()
                } label: {
                    Label("播放信息", systemImage: "info.circle")
                }
                Button {
                    model.reloadCurrentEpisode()
                    onInteraction()
                } label: {
                    Label("重新加载", systemImage: "arrow.clockwise")
                }
                if model.isPiPActive {
                    Button {
                        model.togglePiP()
                        onInteraction()
                    } label: {
                        Label("退出画中画", systemImage: "pip.exit")
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .bold))
                    .frame(width: 38, height: 38)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.18), lineWidth: 0.8))
            }
            .accessibilityLabel("更多播放选项")
        }
    }

    // MARK: - 中央

    private var transport: some View {
        HStack(spacing: 34) {
            glassButton(skipSymbol(preferences.backwardSkip, forward: false), size: 50,
                        label: "后退 \(Int(preferences.backwardSkip)) 秒") {
                Haptics.light()
                model.skipBackward()
                onInteraction()
            }

            Button {
                Haptics.medium()
                model.togglePlayPause()
                onInteraction()
            } label: {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 68, height: 68)
                    Circle()
                        .strokeBorder(Color.white.opacity(0.28), lineWidth: 0.9)
                        .frame(width: 68, height: 68)
                    Image(systemName: model.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 24, weight: model.isPlaying ? .bold : .black))
                        .offset(x: model.isPlaying ? 0 : 1.5)
                }
                .shadow(color: .black.opacity(0.3), radius: 12, y: 4)
            }
            .buttonStyle(AppPressStyle(scale: 0.94))
            .accessibilityLabel(model.isPlaying ? "暂停" : "播放")

            glassButton(skipSymbol(preferences.forwardSkip, forward: true), size: 50,
                        label: "前进 \(Int(preferences.forwardSkip)) 秒") {
                Haptics.light()
                model.skipForward()
                onInteraction()
            }
        }
    }

    // MARK: - 底部

    private var bottomBar: some View {
        VStack(spacing: 8) {
            HStack(alignment: .bottom, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(model.episodeLabel) · \(model.sourceName)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.58))
                        .lineLimit(1)
                    Text(model.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                .shadow(color: .black.opacity(0.35), radius: 4, y: 1)

                Spacer(minLength: 4)
                bottomActions
            }

            timeline

            HStack {
                Text(AppFormat.time(displayTime))
                    .font(.appMono(10))
                    .foregroundStyle(.white.opacity(0.58))
                Spacer()
                Text(AppFormat.time(model.duration))
                    .font(.appMono(10))
                    .foregroundStyle(.white.opacity(0.58))
            }
        }
    }

    private var bottomActions: some View {
        HStack(spacing: 7) {
            speedMenu

            smallButton("list.number", label: "选集") {
                onInteraction()
                onEpisodes()
            }

            smallButton(
                model.isPiPActive ? "pip.exit" : "pip.enter",
                label: model.isPiPActive ? "退出画中画" : "画中画",
                disabled: !model.isPiPPossible && !model.isPiPActive
            ) {
                model.togglePiP()
                onInteraction()
            }

            AirPlayRouteButton(tint: .white)
                .frame(width: 30, height: 30)
                .accessibilityLabel("隔空播放")

        }
    }

    private var volumePanel: some View {
        HStack(spacing: 7) {
            Button {
                Haptics.selection()
                model.toggleMute()
                onInteraction()
            } label: {
                Image(systemName: model.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.78))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(model.isMuted ? "取消静音" : "静音")
            Slider(
                value: Binding(
                    get: { model.volume },
                    set: { model.setVolume($0) }
                ),
                in: 0...1
            )
            .tint(.white)
            .frame(width: 86)
            .labelsHidden()
        }
        .padding(.horizontal, 10)
        .frame(height: 38)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.16), lineWidth: 0.7))
    }

    private var timeline: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width, 1)
            let total = max(model.duration, 0.01)
            let ratio = CGFloat(min(max(displayTime / total, 0), 1))
            let bufferRatio = CGFloat(min(max(model.bufferedTime / total, 0), 1))

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.19))
                    .frame(height: 4)

                Capsule()
                    .fill(Color.white.opacity(0.10))
                    .frame(width: bufferRatio * width, height: 4)

                Capsule()
                    .fill(AppTheme.brandGradient)
                    .frame(width: ratio * width, height: 4)

                Circle()
                    .fill(.white)
                    .frame(width: isScrubbing ? 15 : 11, height: isScrubbing ? 15 : 11)
                    .shadow(color: .black.opacity(0.35), radius: 3, y: 1)
                    .offset(x: ratio * width - (isScrubbing ? 7.5 : 5.5))
            }
            .frame(maxHeight: .infinity, alignment: .center)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard model.duration > 0 else { return }
                        if !isScrubbing {
                            isScrubbing = true
                        }
                        let fraction = min(max(value.location.x / width, 0), 1)
                        scrubTime = Double(fraction) * model.duration
                        onInteraction()
                    }
                    .onEnded { value in
                        guard model.duration > 0 else {
                            isScrubbing = false
                            return
                        }
                        let fraction = min(max(value.location.x / width, 0), 1)
                        let target = Double(fraction) * model.duration
                        isScrubbing = false
                        Haptics.light()
                        model.seek(to: target)
                        onInteraction()
                    }
            )
        }
        .frame(height: 26)
        .overlay(alignment: .top) {
            if isScrubbing {
                Text("\(AppFormat.time(scrubTime)) / \(AppFormat.time(model.duration))")
                    .font(.appMono(11))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .frame(height: 26)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.16), lineWidth: 0.7))
                    .offset(y: -30)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .animation(AppTheme.quick, value: isScrubbing)
    }

    private var speedMenu: some View {
        Menu {
            ForEach(PlaybackPreferences.rates, id: \.self) { value in
                Button {
                    Haptics.selection()
                    model.setRate(value)
                    onInteraction()
                } label: {
                    HStack {
                        Text(rateLabel(value))
                        if abs(model.rate - value) < 0.01 {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Text(rateLabel(model.rate))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.88))
                .frame(width: 40, height: 30)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.16), lineWidth: 0.7))
        }
        .accessibilityLabel("播放速度 \(rateLabel(model.rate))")
    }

    private var scrim: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black.opacity(0.72), Color.black.opacity(0.10), .clear],
                startPoint: .top,
                endPoint: .center
            )
            LinearGradient(
                colors: [.clear, Color.black.opacity(0.50), Color.black.opacity(0.86)],
                startPoint: .center,
                endPoint: .bottom
            )
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func glassButton(_ systemImage: String, size: CGFloat, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size * 0.34, weight: .semibold))
                .frame(width: size, height: size)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().strokeBorder(Color.white.opacity(0.20), lineWidth: 0.8))
                .shadow(color: .black.opacity(0.22), radius: 8, y: 3)
        }
        .buttonStyle(AppPressStyle())
        .accessibilityLabel(label)
    }

    private func smallButton(
        _ systemImage: String,
        label: String,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(disabled ? .white.opacity(0.25) : .white.opacity(0.82))
                .frame(width: 30, height: 30)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().strokeBorder(Color.white.opacity(0.14), lineWidth: 0.7))
        }
        .buttonStyle(AppPressStyle())
        .disabled(disabled)
        .accessibilityLabel(label)
    }

    private func skipSymbol(_ seconds: Double, forward: Bool) -> String {
        let value = Int(seconds)
        let supported: Set<Int> = [10, 15, 30, 45, 60, 75, 90]
        guard supported.contains(value) else { return forward ? "goforward" : "gobackward" }
        return (forward ? "goforward." : "gobackward.") + "\(value)"
    }

    private func qualityName(_ value: Int) -> String {
        if value >= 2160 { return "4K" }
        if value >= 1080 { return "1080P" }
        if value >= 720 { return "720P" }
        return "\(value)P"
    }

    private func rateLabel(_ value: Double) -> String {
        if value == floor(value) { return "\(Int(value))x" }
        return "\(value)x"
    }
}

/// 字幕 / 音轨菜单。横屏 HUD 和竖屏 HUD 共用，避免两套逻辑漂移。
struct PlayerTrackMenu: View {
    @ObservedObject var model: PlayerModel
    let onInteraction: () -> Void

    @ViewBuilder
    var body: some View {
        if model.hasSubtitleOptions {
            Menu {
                if model.subtitlesCanBeDisabled {
                    Button {
                        model.selectSubtitleTrack(id: nil)
                        onInteraction()
                    } label: {
                        HStack {
                            Text("关闭字幕")
                            if model.selectedSubtitleID == nil {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
                ForEach(model.subtitleOptions) { option in
                    Button {
                        model.selectSubtitleTrack(id: option.id)
                        onInteraction()
                    } label: {
                        HStack {
                            Text(option.title)
                            if model.selectedSubtitleID == option.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Label("字幕 · \(model.selectedSubtitleName)", systemImage: "captions.bubble")
            }
        }

        if model.hasAudioOptions {
            Menu {
                ForEach(model.audioOptions) { option in
                    Button {
                        model.selectAudioTrack(id: option.id)
                        onInteraction()
                    } label: {
                        HStack {
                            Text(option.title)
                            if model.selectedAudioID == option.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Label("音轨 · \(model.selectedAudioName)", systemImage: "waveform")
            }
        }
    }
}
