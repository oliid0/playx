import SwiftUI

struct PXSourceCard: View {
    var descriptor: SourceDescriptor
    var count: Int?
    var width: CGFloat = 156

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [PXTheme.backgroundLift, PXTheme.backgroundDeep],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                RadialGradient(
                    colors: [PXTheme.accent.opacity(0.28), .clear],
                    center: .topTrailing,
                    startRadius: 4,
                    endRadius: 130
                )
                VStack(alignment: .leading, spacing: 4) {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(PXTheme.accent)
                    Spacer(minLength: 0)
                    Text(descriptor.displayName)
                        .font(PXFont.title(17))
                        .foregroundStyle(PXTheme.textPrimary)
                    Text(descriptor.subtitle ?? PXCatalogService.sourceTagline(descriptor.id))
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(PXTheme.textTertiary)
                        .lineLimit(1)
                }
                .padding(12)
            }
            .frame(width: width, height: width * 0.72)
            .clipShape(RoundedRectangle(cornerRadius: PXTheme.cardRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PXTheme.cardRadius, style: .continuous)
                    .strokeBorder(PXTheme.stroke, lineWidth: 0.7)
            }
            if let count {
                Text("\(count) 个分类")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(PXTheme.textTertiary)
            }
        }
        .frame(width: width)
    }
}
