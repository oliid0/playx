import Foundation

/// 一条可路由的目录条目：`Drama` 本身没有 provider 实例，UI 导航时按 source
/// 从 `SourceRegistry` 取回对应实现。
struct PXCatalogEntry: Identifiable, Hashable {
    var drama: Drama
    var section: PXCatalogSection
    var providerID: String

    var id: String { drama.id }
    var kind: PXMediaKind { drama.pxKind }
    var provider: ContentProvider? {
        SourceRegistry.descriptor(for: providerID)?.provider
    }
}
