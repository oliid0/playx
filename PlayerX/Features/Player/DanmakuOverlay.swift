import SwiftUI
import AVKit
import QuartzCore

/// 弹幕控制器：跟着播放进度按 30 秒窗口增量拉取（`DanmakuClient`），用简单的"贪心轨道"
/// 避免同一行撞车——不是 guoapp-src 里那套精确的像素级防重叠算法，这里按轨道空闲时间
/// 粗略判断，够用且简单（KISS）。只有 `PlaybackPlan.danmakuId` 非空时才会被创建。
@MainActor
final class DanmakuController: ObservableObject {
    struct ActiveDanmaku: Identifiable {
        let id: String
        let text: String
        let track: Int
    }

    @Published var activeTracks: [ActiveDanmaku] = []
    @Published var isEnabled = true

    private let playbackSession: String
    private var trackCount = 5
    private(set) var travelDuration: Double = 8
    private(set) var fontSize: CGFloat = 15
    private(set) var opacity: Double = 0.92
    private(set) var usesShadow = true
    private var loadedWindowStarts: Set<Int64> = []
    private var trackFreeAt: [Int: TimeInterval] = [:]
    private var timeObserverToken: Any?
    private weak var player: AVPlayer?

    init(playbackSession: String) {
        self.playbackSession = playbackSession
    }

    func apply(fontSize: Double, opacity: Double, speed: Double, tracks: Int, shadow: Bool) {
        self.fontSize = CGFloat(fontSize)
        self.opacity = min(max(opacity, 0.25), 1)
        self.travelDuration = min(max(speed, 4), 16)
        self.trackCount = min(max(tracks, 1), 8)
        self.usesShadow = shadow
    }

    func attach(to player: AVPlayer) {
        self.player = player
        let interval = CMTime(seconds: 1, preferredTimescale: 1)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            // addPeriodicTimeObserver 的闭包类型不是 @MainActor 隔离的（即便 queue: .main 保证了
            // 运行时在主线程），编译器不知道这点，Task { @MainActor in } 把这次调用显式跳回主 actor。
            Task { @MainActor [weak self] in
                guard let self, self.isEnabled, time.seconds.isFinite, time.seconds >= 0 else { return }
                self.ensureWindowLoaded(currentSeconds: time.seconds)
            }
        }
    }

    func detach() {
        if let timeObserverToken {
            player?.removeTimeObserver(timeObserverToken)
        }
        timeObserverToken = nil
    }

    private func ensureWindowLoaded(currentSeconds: Double) {
        let windowStartMs = Int64(currentSeconds / 30) * 30 * 1000
        guard !loadedWindowStarts.contains(windowStartMs) else { return }
        loadedWindowStarts.insert(windowStartMs)
        Task { await loadWindow(startMs: windowStartMs) }
    }

    private func loadWindow(startMs: Int64) async {
        guard let page = try? await DanmakuClient.fetchWindow(playbackSession: playbackSession, startMs: startMs) else {
            return
        }
        for item in page.items {
            schedule(item)
        }
    }

    private func schedule(_ item: DanmakuItem) {
        guard isEnabled else { return }
        let track = pickTrack()
        let entry = ActiveDanmaku(id: item.id, text: item.text, track: track)
        activeTracks.append(entry)
        trackFreeAt[track] = CACurrentMediaTime() + travelDuration * 0.6
        DispatchQueue.main.asyncAfter(deadline: .now() + travelDuration) { [weak self] in
            self?.activeTracks.removeAll { $0.id == entry.id }
        }
    }

    private func pickTrack() -> Int {
        let now = CACurrentMediaTime()
        for track in 0..<trackCount where (trackFreeAt[track] ?? 0) < now {
            return track
        }
        return Int.random(in: 0..<trackCount)
    }
}

/// 滚动弹幕的纯展示层，盖在播放器上面，不拦截点击。
struct DanmakuOverlay: View {
    @ObservedObject var controller: DanmakuController

    var body: some View {
        if controller.isEnabled {
            GeometryReader { proxy in
                ZStack(alignment: .topLeading) {
                    ForEach(controller.activeTracks) { item in
                        DanmakuLine(
                            text: item.text,
                            travelWidth: proxy.size.width,
                            fontSize: controller.fontSize,
                            opacity: controller.opacity,
                            usesShadow: controller.usesShadow,
                            travelDuration: controller.travelDuration
                        )
                        .offset(y: CGFloat(item.track) * (controller.fontSize + 13) + 12)
                    }
                }
            }
            .allowsHitTesting(false)
        }
    }
}

private struct DanmakuLine: View {
    let text: String
    let travelWidth: CGFloat
    let fontSize: CGFloat
    let opacity: Double
    let usesShadow: Bool
    let travelDuration: Double
    @State private var offsetX: CGFloat = 0

    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: .semibold))
            .foregroundStyle(.white.opacity(opacity))
            .shadow(color: usesShadow ? .black.opacity(0.82) : .clear, radius: usesShadow ? 1 : 0)
            .fixedSize()
            .offset(x: offsetX)
            .onAppear {
                offsetX = travelWidth
                withAnimation(.linear(duration: travelDuration)) {
                    offsetX = -max(320, travelWidth * 0.55)
                }
            }
    }
}
