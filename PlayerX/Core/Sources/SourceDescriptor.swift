import Foundation

/// 一个内容源在 UI 里的描述。站源与外部媒体源共用；外部源的 provider 由
/// 配置工厂创建，因此同一个类型可以直接用于首页媒体库、筛选和详情路由。
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
