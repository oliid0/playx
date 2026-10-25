import Foundation

/// 所有在线站源的通用实现。目录/搜索/详情/播放直链解析全部转发给 vendor 进来的 Go 核心
/// （`native/core/provider_*.go`：各站源的反爬/签名/反混淆逻辑）——这套是对各站源私有协议的
/// 逆向实现，milestone 1 不碰，见 Documentation/Architecture.md。
///
/// Go 核心内部按 `source` 字段 switch 分派到各自的 `fetchXxxCatalogPage`/`fetchXxxDetail`/
/// `resolveProviderMedia`，但对外的 `categories`/`catalog`/`detail`/`resolve` 四个 action 的
/// 请求/响应形状对所有站源完全一致，所以这里不需要给每个站源单独写一个 struct。
struct RemoteSourceProvider: ContentProvider {
    let sourceId: String
    let displayName: String
    var sourceKind: PXSourceKind { .station }
    var sourceSubtitle: String? { nil }
    var configurationID: String? { nil }

    func categories() async throws -> [SourceCategory] {
        struct Response: Decodable { let items: [SourceCategory] }
        let response: Response = try await NativeBridge.call(
            NativeRequest(action: "categories", source: sourceId)
        )
        return response.items
    }

    func catalog(category: String, page: Int, query: String? = nil) async throws -> CatalogResult {
        try await NativeBridge.call(
            NativeRequest(action: "catalog", source: sourceId, page: page,
                          query: query, category: category)
        )
    }

    func detail(for drama: Drama) async throws -> DetailResult {
        try await NativeBridge.call(
            NativeRequest(action: "detail", drama: drama)
        )
    }

    func resolve(drama: Drama, chapter: Chapter, index: Int, quality: Int?) async throws -> PlaybackPlan {
        let sequence = await PlaybackSequence.shared.next()
        return try await NativeBridge.call(
            NativeRequest(action: "resolve", drama: drama, chapter: chapter,
                          index: index, quality: quality, sequence: sequence)
        )
    }
}
