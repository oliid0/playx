import SwiftUI

struct PXPlayerInfoSheet: View {
    @ObservedObject var model: PXPlayerModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        PXRemoteImage(url: model.metadata?.posterURL, maxPixel: 300)
                            .frame(width: 64, height: 96)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(model.title).font(PXFont.title(18)).foregroundStyle(PXTheme.textPrimary)
                            Text(model.episodeText).font(.system(size: 11)).foregroundStyle(PXTheme.textTertiary)
                            PXMetadataLine(parts: [
                                model.metadata?.yearText,
                                model.metadata?.runtimeText,
                                model.metadata?.contentRating,
                            ].compactMap { $0 })
                        }
                        Spacer()
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        PXInfoRow(title: "内核", value: model.engineKind.title)
                        PXInfoRow(title: "引擎", value: model.engineKind.summary)
                        PXInfoRow(title: "清晰度", value: model.qualityLabel)
                        PXInfoRow(title: "链接", value: model.plan.url)
                        PXInfoRow(title: "类型", value: model.plan.url.lowercased().contains(".m3u8") ? "HLS" : "文件 / 直链")
                        PXInfoRow(title: "当前", value: PXFormat.time(model.currentTime))
                        PXInfoRow(title: "时长", value: PXFormat.time(model.duration))
                        PXInfoRow(title: "分辨率", value: model.snapshot.videoSize == .zero ? nil : "\(Int(model.snapshot.videoSize.width)) × \(Int(model.snapshot.videoSize.height))")
                        PXInfoRow(title: "弹幕", value: "\(model.danmakuCount) 条")
                    }
                    .pxFlatCard()
                    PXPlaybackStatsView(stats: PXPlaybackStats(
                        engine: model.engineKind,
                        snapshot: model.snapshot,
                        danmakuCount: model.danmakuCount
                    ))
                    if let overview = model.metadata?.overview ?? model.request.drama.description {
                        Text(overview)
                            .font(.system(size: 12))
                            .foregroundStyle(PXTheme.textSecondary)
                            .lineSpacing(4)
                            .pxFlatCard()
                    }
                }
                .padding(20)
            }
            .background(PXPageBackground())
            .navigationTitle("播放信息")
            .pxInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
