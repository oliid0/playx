import SwiftUI

struct PXEpisodeCard: View {
    var chapter: Chapter
    var index: Int
    var isCurrent: Bool = false
    var isWatched: Bool = false
    var progress: Double = 0
    var durationText: String?

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isCurrent ? PXTheme.accent : PXTheme.surface)
                if isCurrent {
                    Image(systemName: "play.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.black.opacity(0.82))
                } else {
                    Text(String(format: "%02d", index))
                        .font(PXFont.mono(12))
                        .foregroundStyle(PXTheme.textSecondary)
                }
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 4) {
                Text(chapter.title.isEmpty ? "第 \(index) 集" : chapter.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isCurrent ? PXTheme.accentSoft : PXTheme.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    if isWatched {
                        Label("已看", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(PXTheme.mint)
                    }
                    if let durationText {
                        Text(durationText)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(PXTheme.textTertiary)
                    }
                    if chapter.vip == true {
                        PXTag(text: "VIP", tint: PXTheme.accent)
                    }
                }
                if progress > 0.01 {
                    PXProgressBar(value: progress, height: 2)
                        .frame(maxWidth: 150)
                }
            }
            Spacer(minLength: 4)
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(PXTheme.textTertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(isCurrent ? PXTheme.accent.opacity(0.09) : Color.clear)
        .overlay(alignment: .bottom) {
            Rectangle().fill(PXTheme.stroke.opacity(0.6)).frame(height: 0.5).padding(.leading, 66)
        }
    }
}
