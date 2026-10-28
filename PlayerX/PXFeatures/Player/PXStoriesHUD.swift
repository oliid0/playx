import SwiftUI

struct PXStoriesHUD: View {
    @ObservedObject var model: PXPlayerModel
    var onClose: () -> Void
    var onEpisodes: () -> Void
    var onSettings: () -> Void
    var onInfo: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.black.opacity(0.62), .clear, .clear, .black.opacity(0.78)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 10) {
                topBar
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(model.title)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Text(model.episodeText)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.62))
                    }
                    .shadow(color: .black.opacity(0.4), radius: 6)
                    Spacer()
                    VStack(spacing: 13) {
                        circleButton(model.isDanmakuEnabled ? "text.bubble.fill" : "text.bubble", label: "弹幕") {
                            model.toggleDanmaku()
                        }
                        circleButton("rectangle.stack", label: "选集", action: onEpisodes)
                        circleButton("slider.horizontal.3", label: "设置", action: onSettings)
                        circleButton("info.circle", label: "信息", action: onInfo)
                        circleButton(model.isLocked ? "lock.fill" : "lock.open", label: "锁定") {
                            model.toggleLock()
                        }
                    }
                    .padding(.top, 6)
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)

                Spacer()

                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        Button { model.playPrevious() } label: {
                            Image(systemName: "backward.end.fill").font(.system(size: 17, weight: .bold))
                        }
                        .disabled(!model.hasPrevious)
                        Button { model.togglePlayPause() } label: {
                            Image(systemName: model.snapshot.state.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 30, weight: .black))
                                .frame(width: 58, height: 58)
                                .background(.ultraThinMaterial, in: Circle())
                                .overlay(Circle().strokeBorder(.white.opacity(0.16), lineWidth: 0.8))
                        }
                        Button { model.playNext() } label: {
                            Image(systemName: "forward.end.fill").font(.system(size: 17, weight: .bold))
                        }
                        .disabled(!model.hasNext)
                    }
                    .foregroundStyle(.white)
                    .buttonStyle(PXPressStyle(scale: 0.92))

                    HStack(spacing: 14) {
                        Label("\(model.danmakuCount)", systemImage: "text.bubble")
                            .font(.system(size: 10, weight: .semibold))
                        Text(PXFormat.time(model.currentTime))
                            .font(PXFont.mono(10))
                        Text(PXFormat.time(model.duration))
                            .font(PXFont.mono(10))
                            .foregroundStyle(.white.opacity(0.54))
                        Spacer()
                        Button {
                            model.cycleRate()
                        } label: {
                            Text(String(format: "%.2gx", model.snapshot.rate))
                                .font(.system(size: 10, weight: .bold))
                        }
                        .buttonStyle(.plain)
                    }
                    .foregroundStyle(.white.opacity(0.78))
                    .padding(.horizontal, 22)

                    PXScrubBar(model: model)
                        .padding(.horizontal, 20)
                }
                .padding(.bottom, 22)
            }
            .padding(.top, 8)
        }
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)

            HStack(spacing: 3) {
                ForEach(model.chapters.indices, id: \.self) { index in
                    Capsule()
                        .fill(index < model.currentIndex
                              ? Color.white.opacity(0.92)
                              : (index == model.currentIndex ? PXTheme.accent : Color.white.opacity(0.24)))
                        .frame(maxWidth: .infinity)
                        .frame(height: 3)
                        .overlay {
                            if index == model.currentIndex {
                                GeometryReader { proxy in
                                    Capsule().fill(.white.opacity(0.92))
                                        .frame(width: proxy.size.width * model.progress)
                                }
                            }
                        }
                }
            }
            .frame(maxWidth: .infinity)

            Button(action: onInfo) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
    }

    private func circleButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().strokeBorder(.white.opacity(0.14), lineWidth: 0.7))
        }
        .buttonStyle(PXPressStyle(scale: 0.9))
        .accessibilityLabel(label)
    }
}

struct PXStoriesTapZones: View {
    var sideWidth: CGFloat
    var onPrevious: () -> Void
    var onNext: () -> Void
    var onToggleControls: () -> Void
    var onBoost: () -> Void = {}
    var onEndBoost: () -> Void = {}
    var enabled: Bool

    var body: some View {
        HStack(spacing: 0) {
            sideZone
                .frame(width: sideWidth)
                .onTapGesture { onPrevious() }
                .onLongPressGesture(minimumDuration: 0.35, pressing: { pressing in
                    pressing ? onBoost() : onEndBoost()
                }, perform: {})
            Color.black.opacity(0.001)
                .contentShape(Rectangle())
                .onTapGesture { onToggleControls() }
            sideZone
                .frame(width: sideWidth)
                .onTapGesture { onNext() }
                .onLongPressGesture(minimumDuration: 0.35, pressing: { pressing in
                    pressing ? onBoost() : onEndBoost()
                }, perform: {})
        }
        .ignoresSafeArea()
        .allowsHitTesting(enabled || true)
    }

    private var sideZone: some View {
        Color.black.opacity(0.001)
            .contentShape(Rectangle())
    }
}

/// 竖屏视频且画面填满屏幕时，左右没有可点击空白；按抖音式上下滑动切换。
struct PXPortraitSwipeLayer: View {
    @ObservedObject var model: PXPlayerModel
    var onPrevious: () -> Void
    var onNext: () -> Void
    @State private var offset: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            Color.black.opacity(0.001)
                .contentShape(Rectangle())
                .onTapGesture {
                    if model.controlsVisible { model.hideControls() } else { model.revealsControls() }
                }
                .gesture(
                    DragGesture(minimumDistance: 28)
                        .onChanged { value in
                            guard abs(value.translation.height) > abs(value.translation.width) else { return }
                            offset = value.translation.height
                        }
                        .onEnded { value in
                            let vertical = abs(value.translation.height) > abs(value.translation.width)
                            if vertical, value.translation.height < -70 {
                                onNext()
                            } else if vertical, value.translation.height > 70 {
                                onPrevious()
                            }
                            withAnimation(PXTheme.quick) { offset = 0 }
                        }
                )
            if abs(offset) > 18 {
                VStack {
                    Spacer()
                    Text(offset < 0 ? "上滑切换下一集" : "下滑切换上一集")
                        .font(PXFont.caption(11))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                    Spacer().frame(height: proxy.size.height * 0.18)
                }
                .allowsHitTesting(false)
            }
        }
        .ignoresSafeArea()
    }
}
