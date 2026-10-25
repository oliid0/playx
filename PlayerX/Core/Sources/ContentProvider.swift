import Foundation

/// 站源抽象。Go 原生核心内部是"函数签名约定 + 分散 switch"（没有真正的 interface，
/// 新增站源要改 5+ 处文件，调研报告里指出这是架构债务），这里改成真正的 protocol——
/// 每新增一个站源，写一个实现即可，不用到处加 case。
///
/// 所有方法最终都落到 `NativeBridge.call`，因为目录/搜索/详情/播放直链解析这些重活
/// 仍然在 vendor 进来的 Go 核心里（签名算法、反爬、各站源私有协议），milestone 1 阶段
/// 不重写这部分逻辑——跑通基础架构、真机测过内存情况后再和用户商量要不要把某个站源
/// 改写成纯 Swift。
protocol ContentProvider {
    /// 对应 Go 侧 `source` 字段，如 `"hongguo"`。
    var sourceId: String { get }
    var displayName: String { get }

    func categories() async throws -> [SourceCategory]
    func catalog(category: String, page: Int, query: String?) async throws -> CatalogResult
    func detail(for drama: Drama) async throws -> DetailResult
    func resolve(drama: Drama, chapter: Chapter, index: Int, quality: Int?) async throws -> PlaybackPlan
}
