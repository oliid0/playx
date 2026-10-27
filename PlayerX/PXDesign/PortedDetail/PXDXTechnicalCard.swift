import SwiftUI

struct PXDXTechnicalCard: View {
    let drama: Drama
    let chapters: [Chapter]
    var body: some View {
        PXUIGlassPanel {
            VStack(alignment: .leading, spacing: 8) {
                Text("媒体信息").font(PXFont.section(15))
                PXUIKeyValueRow(key: "集数", value: drama.episodes.map(String.init) ?? "\(chapters.count)")
                PXUIKeyValueRow(key: "站源", value: SourceRegistry.descriptor(for: drama.source)?.displayName ?? drama.source)
                if let size = chapters.compactMap(\.mediaSize).max() {
                    PXUIKeyValueRow(key: "最大单集", value: PXFormat.byteCount(size))
                }
                PXUIKeyValueRow(key: "分类", value: drama.category ?? "—")
            }
        }
    }
}
