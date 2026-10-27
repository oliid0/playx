import SwiftUI

struct PXWStatsGrid: View {
    let snapshot: PXPlayerSnapshot
    let engine: PXPlayerEngineKind
    var body: some View {
        VStack(spacing: 0) {
            PXWInfoRow(label: "内核", value: engine.title)
            PXWInfoRow(label: "进度", value: "\(PXFormat.time(snapshot.currentTime)) / \(PXFormat.time(snapshot.duration))")
            PXWInfoRow(label: "缓冲", value: PXFormat.time(snapshot.buffered))
            PXWInfoRow(label: "分辨率", value: snapshot.videoSize == .zero ? "—" : "\(Int(snapshot.videoSize.width))×\(Int(snapshot.videoSize.height))")
            PXWInfoRow(label: "音轨", value: "\(snapshot.audioTracks.count)")
            PXWInfoRow(label: "字幕", value: "\(snapshot.subtitleTracks.count)")
        }
    }
}
