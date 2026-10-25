import SwiftUI

struct PXDanmakuOverlay: View {
    @ObservedObject var coordinator: PXDanmakuCoordinator
    var currentTime: Double
    var isEnabled: Bool
    @State private var active: [ActiveComment] = []
    @State private var lastTime: Double = 0
    @State private var lanes: [Int: Double] = [:]

    private struct ActiveComment: Identifiable {
        let id: String
        let text: String
        let lane: Int
        let isFixed: Bool
        let fixedPosition: PXDanmakuMode
        let color: Color
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                ForEach(active) { item in
                    if item.isFixed {
                        FixedDanmakuLine(text: item.text, color: item.color, fontSize: CGFloat(PXPlayerPreferences.shared.danmakuFontSize))
                            .frame(maxWidth: .infinity)
                            .offset(y: CGFloat(item.lane) * 32 + 58)
                    } else {
                        ScrollingDanmakuLine(
                            text: item.text,
                            color: item.color,
                            fontSize: CGFloat(PXPlayerPreferences.shared.danmakuFontSize),
                            travelWidth: proxy.size.width,
                            duration: PXPlayerPreferences.shared.danmakuSpeed
                        )
                        .offset(y: CGFloat(item.lane) * 30 + 62)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .opacity(isEnabled ? 1 : 0)
        .onChange(of: currentTime) { time in
            guard isEnabled else { lastTime = time; return }
            if time < lastTime - 1.5 {
                active.removeAll()
                lanes.removeAll()
            }
            dispatch(from: lastTime, to: time)
            lastTime = time
        }
        .onChange(of: coordinator.comments.count) { _ in
            active.removeAll()
            lastTime = currentTime
        }
    }

    private func dispatch(from oldTime: Double, to now: Double) {
        let windowStart = max(0, oldTime - 0.2)
        let fresh = coordinator.comments.filter { $0.time > windowStart && $0.time <= now + 0.2 }
        guard !fresh.isEmpty else { return }
        let maxLanes = max(1, PXPlayerPreferences.shared.danmakuTracks)
        for comment in fresh.prefix(18) {
            let lane = pickLane(at: comment.time, maxLanes: maxLanes, isFixed: comment.mode != .scroll)
            let item = ActiveComment(
                id: comment.id,
                text: comment.text,
                lane: lane,
                isFixed: comment.mode != .scroll,
                fixedPosition: comment.mode,
                color: Color(
                    red: Double((comment.color >> 16) & 0xFF) / 255,
                    green: Double((comment.color >> 8) & 0xFF) / 255,
                    blue: Double(comment.color & 0xFF) / 255
                )
            )
            active.append(item)
            let lifetime = comment.mode == .scroll ? PXPlayerPreferences.shared.danmakuSpeed + 0.8 : 4.0
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(lifetime * 1_000_000_000))
                active.removeAll { $0.id == item.id }
            }
        }
        if active.count > 90 { active.removeFirst(active.count - 90) }
    }

    private func pickLane(at time: Double, maxLanes: Int, isFixed: Bool) -> Int {
        if !isFixed {
            for lane in 0..<maxLanes where (lanes[lane] ?? 0) <= time {
                lanes[lane] = time + PXPlayerPreferences.shared.danmakuSpeed * 0.58
                return lane
            }
        }
        return Int.random(in: 0..<maxLanes)
    }
}

private struct ScrollingDanmakuLine: View {
    var text: String
    var color: Color
    var fontSize: CGFloat
    var travelWidth: CGFloat
    var duration: Double
    @State private var offsetX: CGFloat = 0

    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: .semibold))
            .foregroundStyle(color.opacity(PXPlayerPreferences.shared.danmakuOpacity))
            .shadow(color: .black.opacity(PXPlayerPreferences.shared.danmakuShadow ? 0.9 : 0), radius: 2, x: 0, y: 1)
            .fixedSize()
            .offset(x: offsetX)
            .onAppear {
                offsetX = travelWidth + 20
                withAnimation(.linear(duration: duration)) {
                    offsetX = -max(360, travelWidth * 0.62)
                }
            }
    }
}

private struct FixedDanmakuLine: View {
    var text: String
    var color: Color
    var fontSize: CGFloat

    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: .bold))
            .foregroundStyle(color.opacity(PXPlayerPreferences.shared.danmakuOpacity))
            .shadow(color: .black.opacity(0.9), radius: 2, x: 0, y: 1)
            .multilineTextAlignment(.center)
            .lineLimit(2)
    }
}
