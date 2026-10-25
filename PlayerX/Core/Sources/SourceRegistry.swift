import Foundation

/// 一个站源在 UI 里的描述：provider 本身 + 默认是否直接展示。
/// 对应 guoapp-src README 里"默认可见站源（红果/韩小圈/鬼片/青空）无需密码；
/// 其余站源默认隐藏，在站源管理里通过密码锁解锁后显示"。
struct SourceDescriptor: Identifiable {
    let provider: ContentProvider
    let defaultVisible: Bool
    var id: String { provider.sourceId }
    var displayName: String { provider.displayName }
    var kind: PXSourceKind { provider.sourceKind }
    var subtitle: String? { provider.sourceSubtitle }
    var symbol: String { provider.sourceKind.symbol }
    var isExternal: Bool { provider.sourceKind != .station }
    var configurationID: String? { provider.configurationID }
}

/// 当前接入的全部站源。Go 核心编译时已经把所有站源都打进了 `DuanjuCore.xcframework`
/// （`scripts/build-core-xcframework.sh --all-sources`），这里只是 UI 要不要默认展示的问题，
/// 不是能不能访问的问题——被锁的站源数据/网络能力和默认站源完全对等，见
/// Documentation/Architecture.md「站源密码锁」。
///
/// 站源 id 必须和 Go 侧 `provider_huangguo.go` 里的 `source*` 常量字符串完全一致。
enum SourceRegistry {
    static let stationSources: [SourceDescriptor] = [
        .init(provider: RemoteSourceProvider(sourceId: "hongguo", displayName: "红果"), defaultVisible: true),
        .init(provider: RemoteSourceProvider(sourceId: "hanxiaoquan", displayName: "韩小圈"), defaultVisible: true),
        .init(provider: RemoteSourceProvider(sourceId: "guipian", displayName: "鬼片"), defaultVisible: true),
        .init(provider: RemoteSourceProvider(sourceId: "sorani", displayName: "青空"), defaultVisible: true),
        .init(provider: RemoteSourceProvider(sourceId: "huangdou", displayName: "黄豆"), defaultVisible: false),
        .init(provider: RemoteSourceProvider(sourceId: "huangju", displayName: "剧果"), defaultVisible: false),
        .init(provider: RemoteSourceProvider(sourceId: "yeguo", displayName: "野果"), defaultVisible: false),
        .init(provider: RemoteSourceProvider(sourceId: "dsd", displayName: "帝果"), defaultVisible: false),
        .init(provider: RemoteSourceProvider(sourceId: "huangguo-video", displayName: "黄果视频"), defaultVisible: false),
        .init(provider: RemoteSourceProvider(sourceId: "huangguoai", displayName: "黄果 AI"), defaultVisible: false),
        .init(provider: RemoteSourceProvider(sourceId: "cloudfront", displayName: "黄果旧版"), defaultVisible: false),
    ]

    /// 内置站源 + 用户配置的外部媒体源。外部源快照由配置存储在保存后刷新。
    static var all: [SourceDescriptor] {
        stationSources + PXExternalSourceRegistry.descriptors
    }

    static func descriptor(for sourceId: String) -> SourceDescriptor? {
        all.first { $0.id == sourceId }
    }

    @MainActor static func reloadExternalSources() {
        PXExternalSourceRegistry.reload(PXSourceConfigurationStore.shared.configurations)
    }
}
