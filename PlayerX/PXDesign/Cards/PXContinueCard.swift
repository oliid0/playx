import SwiftUI

struct PXContinueCard: View {
    var entry: HistoryEntry
    var width: CGFloat = 280

    private var progress: Double {
        guard entry.duration > 0 else { return 0 }
        return min(max(entry.position / entry.duration, 0), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            ZStack(alignment: .bottomLeading) {
                PXRemoteImage(url: URL(string: entry.drama.cover ?? ""), maxPixel: width * 2.4)
                    .aspectRatio(16 / 9, contentMode: .fill)
                    .frame(width: width, height: width * 9 / 16)
                    .clipped()
                LinearGradient(colors: [.clear, .black.opacity(0.72)], startPoint: .center, endPoint: .bottom)
                HStack(spacing: 7) {
                    ZStack {
                        Circle().fill(PXTheme.accent).frame(width: 30, height: 30)
                        Image(systemName: "play.fill")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(.black.opacity(0.84))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.chapter.title)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Text(PXFormat.timeLeft(current: entry.position, duration: entry.duration))
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.white.opacity(0.62))
                    }
                }
                .padding(10)
            }
            .frame(width: width, height: width * 9 / 16)
            .clipShape(RoundedRectangle(cornerRadius: PXTheme.posterRadius, style: .continuous))
            .overlay(alignment: .bottom) {
                PXProgressBar(value: progress, height: 3)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 5)
            }

            Text(entry.drama.title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(PXTheme.textPrimary)
                .lineLimit(1)
            Text("第 \(entry.episodeIndex) 集 · \(PXFormat.relative(entry.updatedAt))")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(PXTheme.textTertiary)
        }
        .frame(width: width, alignment: .leading)
        .pxHoverLift()
    }
}
