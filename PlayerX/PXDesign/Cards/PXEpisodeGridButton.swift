import SwiftUI

struct PXEpisodeGridButton: View {
    var index: Int
    var chapter: Chapter
    var selected: Bool
    var downloaded: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text(String(format: "%02d", index))
                .font(PXFont.mono(14))
            if downloaded {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 7))
                    .foregroundStyle(PXTheme.mint)
            }
        }
        .foregroundStyle(selected ? .black.opacity(0.86) : PXTheme.textSecondary)
        .frame(maxWidth: .infinity)
        .frame(height: 46)
        .background(selected ? PXTheme.accent : PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 9))
        .overlay {
            RoundedRectangle(cornerRadius: 9)
                .strokeBorder(selected ? .clear : PXTheme.stroke, lineWidth: 0.6)
        }
    }
}
