import SwiftUI

struct PXMoviePilotSubscriptionsView: View {
    @ObservedObject private var coordinator = PXMoviePilotCoordinator.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if coordinator.subscriptions.isEmpty {
                PXEmptyState(title: "还没有订阅", message: "在找片页搜索媒体，点击订阅后会自动追更。", symbol: "bell.slash")
            } else {
                ForEach(coordinator.subscriptions) { item in
                    HStack(spacing: 11) {
                        PXRemoteImage(url: item.posterURL, maxPixel: 240)
                            .frame(width: 48, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.name).font(.system(size: 12, weight: .semibold)).foregroundStyle(PXTheme.textPrimary).lineLimit(1)
                            HStack(spacing: 6) {
                                if let year = item.year { PXTag(text: year) }
                                if let season = item.season { PXTag(text: "第 \(season) 季", tint: PXTheme.sky) }
                                if let state = item.state { PXTag(text: state, tint: PXTheme.mint) }
                            }
                            if let total = item.totalEpisodes, let current = item.currentEpisodes {
                                PXProgressBar(value: total > 0 ? Double(current) / Double(total) : 0, height: 2)
                                    .frame(maxWidth: 150)
                                Text("\(current) / \(total) 集").font(.system(size: 9)).foregroundStyle(PXTheme.textTertiary)
                            }
                        }
                        Spacer()
                        Button {
                            Task { await coordinator.deleteSubscription(item) }
                        } label: {
                            Image(systemName: "trash").font(.system(size: 12)).foregroundStyle(PXTheme.danger)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(9)
                    .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 11))
                }
            }
        }
        .padding(.horizontal, PXTheme.contentPadding)
        .padding(.top, 14)
        .task { await coordinator.loadSubscriptions() }
    }
}
