import Foundation

/// `SourceRegistry.all` 会在后台任务和主线程同时被读。这里用一个极小的锁保护
/// provider 快照，配置保存后整体替换，避免读到一个半更新的数组。
enum PXExternalSourceRegistry {
    private static let lock = NSLock()
    private static var storage: [SourceDescriptor] = []

    static var descriptors: [SourceDescriptor] {
        lock.lock(); defer { lock.unlock() }
        return storage
    }

    static func reload(_ configurations: [PXSourceConfiguration]) {
        let built = configurations
            .filter(\.enabled)
            .compactMap { configuration -> SourceDescriptor? in
                guard configuration.isConfigured,
                      let provider = PXSourceProviderFactory.make(configuration) else { return nil }
                return SourceDescriptor(provider: provider, defaultVisible: true)
            }
        lock.lock()
        storage = built
        lock.unlock()
        PXLog.info("外部媒体源 \(built.count) 个")
    }
}
