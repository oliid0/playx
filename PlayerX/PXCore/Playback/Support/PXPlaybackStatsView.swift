import SwiftUI

struct PXPlaybackStatsView: View {
    var stats: PXPlaybackStats

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            row("内核", stats.engine.title)
            row("状态", stats.state.title)
            row("进度", "\(PXFormat.time(stats.currentTime)) / \(PXFormat.time(stats.duration))")
            row("缓冲", "\(Int(stats.progress * 100))%")
            row("分辨率", stats.resolutionText)
            row("音轨 / 字幕", "\(stats.audioTracks) / \(stats.subtitleTracks)")
            row("倍速", String(format: "%.2gx", stats.rate))
            row("画幅", stats.isPortrait ? "竖屏" : "横屏")
            row("弹幕", "\(stats.danmakuCount) 条")
        }
        .pxFlatCard()
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.system(size: 11, design: .monospaced)).foregroundStyle(.primary)
        }
        .padding(.vertical, 5)
    }
}
