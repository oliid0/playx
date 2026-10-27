import Foundation

enum PXPlayerMediaInfoBuilder {
    static func text(plan: PlaybackPlan, snapshot: PXPlayerSnapshot, engine: PXPlayerEngineKind) -> String {
        var rows = [
            "内核：\(engine.title)",
            "清晰度：\(plan.quality.map(PXFormat.quality) ?? "自动")",
            "进度：\(PXFormat.time(snapshot.currentTime)) / \(PXFormat.time(snapshot.duration))",
        ]
        if snapshot.videoSize != .zero {
            rows.append("分辨率：\(Int(snapshot.videoSize.width)) × \(Int(snapshot.videoSize.height))")
        }
        rows.append("音轨：\(snapshot.audioTracks.count) · 字幕：\(snapshot.subtitleTracks.count)")
        return rows.joined(separator: "\n")
    }
}
