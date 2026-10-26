import SwiftUI

/// 首页「媒体库」栏的卡片：对齐 OcPlayer 的 LibraryCard——用 2×2 内容封面
/// 拼出库的识别图；没有封面时退回渐变底，不造假的服务器封面。
struct PXLibraryCard: View {
    var descriptor: SourceDescriptor
    var covers: [Drama]
    var width: CGFloat = 300

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            ZStack(alignment: .bottomLeading) {
                coverCollage
                    .frame(width: width, height: width * 9 / 16)
                    .clipped()
                LinearGradient(
                    colors: [.clear, .black.opacity(0.74)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                HStack(alignment: .bottom, spacing: 9) {
                    Image(systemName: descriptor.symbol)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(PXTheme.accent)
                        .frame(width: 30, height: 30)
                        .background(.ultraThinMaterial, in: Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text(descriptor.displayName)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Text(descriptor.subtitle ?? PXCatalogService.sourceTagline(descriptor.id))
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.white.opacity(0.62))
                            .lineLimit(1)
                    }
                }
                .padding(12)
            }
            .frame(width: width, height: width * 9 / 16)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(PXTheme.stroke, lineWidth: 0.7)
            }
            Text(descriptor.isExternal ? "外部媒体源" : "内置站源 · \(PXCatalogService.sourceTagline(descriptor.id))")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(PXTheme.textTertiary)
                .lineLimit(1)
        }
        .frame(width: width, alignment: .leading)
        .pxHoverLift()
    }

    private var coverCollage: some View {
       GeometryReader { proxy in
            if covers.count >= 2 {
                let half = proxy.size.width / 2
                HStack(spacing: 0) {
                    VStack(spacing: 0) {
                        PXCoverImage(drama: covers[0], maxPixel: 500).frame(width: half, height: proxy.size.height / 2)
                        PXCoverImage(drama: covers.count > 2 ? covers[2] : covers[0], maxPixel: 500).frame(width: half, height: proxy.size.height / 2)
                    }
                    VStack(spacing: 0) {
                        PXCoverImage(drama: covers[1], maxPixel: 500).frame(width: half, height: proxy.size.height / 2)
                        PXCoverImage(drama: covers.count > 3 ? covers[3] : covers[1], maxPixel: 500).frame(width: half, height: proxy.size.height / 2)
                    }
                }
            } else if let first = covers.first {
                PXCoverImage(drama: first, maxPixel: 800)
                    .frame(width: proxy.size.width, height: proxy.size.height)
            } else {
                ZStack {
                    LinearGradient(colors: [PXTheme.backgroundLift, PXTheme.backgroundDeep], startPoint: .topLeading, endPoint: .bottomTrailing)
                    RadialGradient(colors: [PXTheme.accent.opacity(0.22), .clear], center: .topTrailing, startRadius: 0, endRadius: 180)
                    Image(systemName: descriptor.symbol)
                        .font(.system(size: 46, weight: .black))
                        .foregroundStyle(PXTheme.accent.opacity(0.60))
                }
            }
        }
    }
}
