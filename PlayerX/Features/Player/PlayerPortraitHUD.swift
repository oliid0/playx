import SwiftUI
import AVKit
import Foundation

/// 竖屏视频专用 HUD。参考 Pillarbox Stories 的全屏竖屏思路：不挤压画面、
/// 右侧操作栏 + 左下角元信息 + 底部细进度条，横屏 HUD 继续用 `PlayerHUD`。
struct PlayerPortraitHUD: View {
    @ObservedObject var model: PlayerModel
    @ObservedObject private var preferences = PlaybackPreferences.shared
    @ObservedObject private var follow = FollowStore.shared

    let onClose: () -> Void
    let onEpisodes: () -> Void
    let onInfo: () -> Void
    let onInteraction: () -> Void

    @State private var isScrubbing = false
    @State private var scrubTime: Double = 0

    private var displayTime: Double {
        isScrubbing ? scrubTime : model.currentTime
    }

    private var isFollowed: Bool {
        follow.status(forDramaId: model.drama.id) != nil
    }

    var body: some View {
        ZStack {
            scrim

            VStack(spacing: 0) {
                topBar
                Spacer(minLength: 0)
                HStack(alignment: .bottom, spacing: 12) {
                    metadata
                    Spacer(minLength: 6)
                    actionRail
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
                bottomBar
            }

            if !model.isPlaying && !model.isLoading && model.errorMessage == nil {
                Button {
                    Haptics.medium()
                    model.togglePlayPause()
                    onInteraction()
                } label: {
                    Image(systemName: "play.fill")
                        .font(.system(size: 26, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 66, height: 66)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(Circle().strokeBorder(.white.opacity(0.22), lineWidth: 0.8))
                        .shadow(color: .black.opacity(0.35), radius: 18, y: 6)
                }
                .buttonStyle(AppPressStyle(scale: 0.94))
                .accessibilityLabel("播放")
            }
        }
    }

    // MARK: - 顶部

    private var topBar: some View {
        HStack(spacing: 10) {
            Button {
                Haptics.light()
                onClose()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().strokeBorder(.white.opacity(0.14), lineWidth: 0.7))
            }
            .buttonStyle(AppPressStyle(scale: 0.92))
            .accessibilityLabel("返回")

            VStack(alignment: .leading, spacing: 2) {
                Text(model.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text("\(model.sourceName) · \(model.episodeLabel)")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            moreMenu
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
    }

    private var moreMenu: some View {
        Menu {
            if model.qualities.count > 1 {
                Menu {
                    ForEach(model.qualities, id: \.self) { quality in
                        Button {
                            model.setQuality(quality)
                            onInteraction()
                        } label: {
                            HStack {
                                Text(PlaybackPreferences.qualityTitle(quality))
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
                Label(model.sleepTimerMinutes.map { "定时关闭 · \($0) 分钟" } ?? "定时关闭",
                      systemImage: "moon.zzz")
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
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().strokeBorder(.white.opacity(0.14), lineWidth: 0.7))
        }
        .accessibilityLabel("更多播放选项")
    }

    // MARK: - 左下元信息

    private var metadata: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(model.title)
                .font(.system(size: 17, weight: .black))
                .foregroundStyle(.white)
                .lineLimit(2)
                .shadow(color: .black.opacity(0.4), radius: 4)

            HStack(spacing: 6) {
                Text(model.episodeLabel)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 7)
                    .frame(height: 21)
                    .background(.white.opacity(0.14), in: Capsule())
                if let chapter = model.currentChapter, !chapter.title.isEmpty {
                    Text(chapter.title)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.62))
                        .lineLimit(1)
                }
            }

            if model.hasNextEpisode {
                Label("上滑下一集", systemImage: "chevron.up")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.44))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 右侧操作栏

    private var actionRail: some View {
        VStack(spacing: 15) {
            actionButton(
                icon: isFollowed ? "heart.fill" : "heart",
                title: isFollowed ? "已收藏" : "收藏",
                tint: isFollowed ? AppTheme.brand : .white
            ) {
                Haptics.selection()
                if isFollowed {
                    follow.remove(dramaId: model.drama.id)
                } else {
                    follow.setStatus(.watching, for: model.drama)
                }
                onInteraction()
            }

            actionButton(icon: "list.bullet.rectangle", title: "选集") {
                Haptics.light()
                onEpisodes()
                onInteraction()
            }

            if model.canToggleDanmaku {
                actionButton(
                    icon: model.isDanmakuEnabled ? "text.bubble.fill" : "text.bubble",
                    title: "弹幕",
                    tint: model.isDanmakuEnabled ? AppTheme.brand : .white
                ) {
                    Haptics.selection()
                    model.toggleDanmaku()
                    onInteraction()
                }
            }

            speedMenu

            if model.isPiPPossible {
                actionButton(
                    icon: model.isPiPActive ? "pip.exit" : "pip.enter",
                    title: "画中画"
                ) {
                    Haptics.light()
                    model.togglePiP()
                    onInteraction()
                }
            }

            actionButton(
                icon: model.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                title: model.isMuted ? "已静音" : "声音"
            ) {
                Haptics.selection()
                model.toggleMute()
                onInteraction()
            }
        }
    }

    private func actionButton(
        icon: String,
        title: String,
        tint: Color = .white,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().strokeBorder(.white.opacity(0.14), lineWidth: 0.7))
                Text(title)
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(1)
            }
        }
        .buttonStyle(AppPressStyle(scale: 0.92))
        .accessibilityLabel(title)
    }

    private var speedMenu: some View {
        Menu {
            ForEach(PlaybackPreferences.rates, id: \.self) { rate in
                Button {
                    Haptics.selection()
                    model.setRate(rate)
                    onInteraction()
                } label: {
                    HStack {
                        Text(PlaybackPreferences.rateTitle(rate))
                        if abs(model.rate - rate) < 0.01 {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            VStack(spacing: 4) {
                Text(PlaybackPreferences.rateTitle(model.rate))
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().strokeBorder(.white.opacity(0.14), lineWidth: 0.7))
                Text("倍速")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.72))
            }
        }
        .accessibilityLabel("倍速 \(PlaybackPreferences.rateTitle(model.rate))")
    }

    // MARK: - 底部进度

    private var bottomBar: some View {
        VStack(spacing: 7) {
            HStack(spacing: 9) {
                Text(AppFormat.time(displayTime))
                    .font(.appMono(9))
                    .foregroundStyle(.white.opacity(0.68))
                    .frame(width: 34, alignment: .leading)

                timeline

                Text(AppFormat.time(model.duration))
                    .font(.appMono(9))
                    .foregroundStyle(.white.opacity(0.68))
                    .frame(width: 34, alignment: .trailing)
            }

            HStack(spacing: 12) {
                AirPlayRouteButton(tint: .white)
                    .frame(width: 22, height: 22)
                    .opacity(0.76)

                Button {
                    Haptics.selection()
                    model.toggleMute()
                    onInteraction()
                } label: {
                    Image(systemName: model.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.76))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(model.isMuted ? "取消静音" : "静音")

                Spacer()

                if let timer = model.sleepTimerMinutes {
                    Label("\(timer) 分钟", systemImage: "moon.zzz.fill")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.62))
                }
            }
            .padding(.horizontal, 2)
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 12)
    }

    private var timeline: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width, 1)
            let duration = max(model.duration, 0.1)
            let progress = min(max(displayTime / duration, 0), 1)
            let buffer = min(max(model.bufferedTime / duration, 0), 1)

            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.20)).frame(height: 3)
                Capsule().fill(.white.opacity(0.38)).frame(width: width * buffer, height: 3)
                Capsule().fill(AppTheme.brandGradient).frame(width: width * progress, height: 3)
                Circle()
                    .fill(.white)
                    .frame(width: isScrubbing ? 11 : 8, height: isScrubbing ? 11 : 8)
                    .shadow(color: .black.opacity(0.3), radius: 2)
                    .offset(x: max(0, width * progress - (isScrubbing ? 5.5 : 4)))
            }
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard model.duration > 0 else { return }
                        if !isScrubbing {
                            isScrubbing = true
                            Haptics.light()
                        }
                        scrubTime = min(max(Double(value.location.x / width) * model.duration, 0), model.duration)
                        onInteraction()
                    }
                    .onEnded { _ in
                        if isScrubbing {
                            model.seek(to: scrubTime)
                            isScrubbing = false
                        }
                        onInteraction()
                    }
            )
        }
        .frame(height: 22)
    }

    private var scrim: some View {
        ZStack {
            LinearGradient(
                colors: [.black.opacity(0.62), .clear, .clear, .black.opacity(0.82)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
