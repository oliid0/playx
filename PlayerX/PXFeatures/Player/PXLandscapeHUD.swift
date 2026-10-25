import SwiftUI

struct PXLandscapeHUD: View {
    @ObservedObject var model: PXPlayerModel
    var onClose: () -> Void
    var onEpisodes: () -> Void
    var onSettings: () -> Void
    var onInfo: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.black.opacity(0.58), .clear, .clear, .black.opacity(0.72)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack {
                HStack(spacing: 12) {
                    Button(action: onClose) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(PXPressStyle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text(model.title).font(.system(size: 14, weight: .bold)).foregroundStyle(.white).lineLimit(1)
                        Text(model.episodeText).font(.system(size: 10, weight: .medium)).foregroundStyle(.white.opacity(0.58))
                    }
                    Spacer()
                    Button { model.toggleDanmaku() } label: {
                        Image(systemName: model.isDanmakuEnabled ? "text.bubble.fill" : "text.bubble")
                    }
                    .buttonStyle(PXIconButtonStyle(size: 36))
                    Button { onSettings() } label: { Image(systemName: "slider.horizontal.3") }
                        .buttonStyle(PXIconButtonStyle(size: 36))
                    Button { onInfo() } label: { Image(systemName: "ellipsis") }
                        .buttonStyle(PXIconButtonStyle(size: 36))
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                Spacer()
                HStack(spacing: 30) {
                    Button { model.skipBackward() } label: {
                        Image(systemName: "gobackward.10").font(.system(size: 23, weight: .semibold))
                    }
                    Button { model.togglePlayPause() } label: {
                        Image(systemName: model.snapshot.state.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 34, weight: .black))
                            .frame(width: 68, height: 68)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(Circle().strokeBorder(.white.opacity(0.16)))
                    }
                    Button { model.skipForward() } label: {
                        Image(systemName: "goforward.10").font(.system(size: 23, weight: .semibold))
                    }
                }
                .foregroundStyle(.white)
                .buttonStyle(PXPressStyle(scale: 0.92))
                Spacer()
                VStack(spacing: 10) {
                    PXScrubBar(model: model)
                    HStack(spacing: 14) {
                        Button { onEpisodes() } label: {
                            Label(model.episodeText, systemImage: "rectangle.stack")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .buttonStyle(.plain)
                        Button { model.toggleDanmaku() } label: {
                            Label("\(model.danmakuCount) 条弹幕", systemImage: "text.bubble")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .buttonStyle(.plain)
                        Spacer()
                        Text(PXFormat.time(model.currentTime)).font(PXFont.mono(10))
                        Text("/").foregroundStyle(.white.opacity(0.28))
                        Text(PXFormat.time(model.duration)).font(PXFont.mono(10)).foregroundStyle(.white.opacity(0.56))
                        Button { model.cycleRate() } label: {
                            Text(String(format: "%.2gx", model.snapshot.rate)).font(.system(size: 10, weight: .bold))
                        }
                        .buttonStyle(.plain)
                    }
                    .foregroundStyle(.white.opacity(0.78))
                }
                .padding(.horizontal, 26)
                .padding(.bottom, 22)
            }
        }
    }
}

struct PXNextUpOverlay: View {
    @ObservedObject var model: PXPlayerModel

    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(PXTheme.accent.opacity(0.20)).frame(width: 40, height: 40)
                    Image(systemName: "play.fill").font(.system(size: 14, weight: .bold)).foregroundStyle(PXTheme.accent)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.hasNext ? "即将播放第 \(model.currentIndex + 2) 集" : "已是最后一集")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                    Text(model.nextCountdown > 0 ? "\(model.nextCountdown) 秒后自动播放" : "点按播放下一集")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.56))
                }
                Spacer()
                if model.hasNext {
                    Button("下一集") { model.playNext() }
                        .buttonStyle(PXPrimaryButtonStyle(compact: true))
                }
                Button {
                    model.dismissNextPrompt()
                } label: {
                    Image(systemName: "xmark").font(.system(size: 10, weight: .bold))
                }
                .buttonStyle(PXIconButtonStyle(size: 28))
            }
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.white.opacity(0.14), lineWidth: 0.7))
            .padding(.horizontal, 24)
            .padding(.bottom, 96)
        }
        .allowsHitTesting(true)
    }
}

struct PXPlayerErrorOverlay: View {
    var message: String
    var retry: () -> Void
    var close: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.78).ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(PXTheme.warning)
                Text("播放失败").font(PXFont.title(20)).foregroundStyle(.white)
                Text(message)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.60))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                HStack(spacing: 10) {
                    Button("重试", action: retry).buttonStyle(PXPrimaryButtonStyle(compact: true))
                    Button("返回", action: close).buttonStyle(PXSecondaryButtonStyle(compact: true))
                }
            }
            .padding(24)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
            .padding(.horizontal, 30)
        }
    }
}
