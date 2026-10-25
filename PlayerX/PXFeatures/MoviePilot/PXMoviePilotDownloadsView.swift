import SwiftUI

struct PXMoviePilotDownloadsView: View {
    @ObservedObject private var coordinator = PXMoviePilotCoordinator.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if coordinator.downloads.isEmpty {
                PXEmptyState(title: "没有下载任务", message: "资源页点击下载后，进度会在这里实时更新。", symbol: "arrow.down.circle")
            } else {
                ForEach(coordinator.downloads) { item in
                    HStack(spacing: 11) {
                        PXRemoteImage(url: item.posterURL, maxPixel: 180)
                            .frame(width: 42, height: 62)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name).font(.system(size: 11, weight: .semibold)).foregroundStyle(PXTheme.textPrimary).lineLimit(2)
                            PXProgressBar(value: item.progress, height: 3)
                            HStack(spacing: 8) {
                                Text(PXFormat.percent(item.progress)).font(PXFont.mono(9)).foregroundStyle(PXTheme.textTertiary)
                                if let size = item.size { Text(PXFormat.byteCount(size)).font(.system(size: 9)).foregroundStyle(PXTheme.textTertiary) }
                                if let speed = item.speedText { Text(speed).font(.system(size: 9)).foregroundStyle(PXTheme.mint) }
                            }
                        }
                        Spacer()
                        if let state = item.state {
                            PXTag(text: state, tint: item.progress >= 1 ? PXTheme.mint : PXTheme.accent)
                        }
                    }
                    .padding(9)
                    .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 11))
                }
            }
        }
        .padding(.horizontal, PXTheme.contentPadding)
        .padding(.top, 14)
        .task { await coordinator.loadDownloads() }
    }
}
