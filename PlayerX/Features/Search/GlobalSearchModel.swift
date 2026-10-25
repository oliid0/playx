import Foundation
import Combine

/// 全站搜索模型：勾选「全部」时并发请求所有可见站源，按站源顺序合并去重。
/// 单个站源失败/超时只丢它自己的结果，不阻塞其它站源。
@MainActor
final class GlobalSearchModel: ObservableObject {
    @Published var query = ""
    @Published var scopeSourceId: String? = nil
    @Published private(set) var results: [Drama] = []
    @Published private(set) var isSearching = false
    @Published private(set) var hasSearched = false
    @Published private(set) var errorMessage: String?

    private var generation = 0

    var availableSources: [SourceDescriptor] {
        SourceRegistry.all.filter { descriptor in
            descriptor.defaultVisible || SourceLockStore.shared.isUnlockedThisLaunch
        }
    }

    var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func clear() {
        generation += 1
        results = []
        isSearching = false
        hasSearched = false
        errorMessage = nil
    }

    func search() async {
        let keyword = trimmedQuery
        guard !keyword.isEmpty else {
            clear()
            return
        }

        generation += 1
        let currentGeneration = generation
        let descriptors: [SourceDescriptor]
        if let scopeSourceId, let scoped = availableSources.first(where: { $0.id == scopeSourceId }) {
            descriptors = [scoped]
        } else {
            descriptors = availableSources
        }

        isSearching = true
        hasSearched = true
        errorMessage = nil

        var bySource: [String: [Drama]] = [:]
        var failures = 0

        await withTaskGroup(of: (String, [Drama]?).self) { group in
            for descriptor in descriptors {
                group.addTask {
                    let items = await Self.search(descriptor: descriptor, keyword: keyword)
                    return (descriptor.id, items)
                }
            }
            for await (sourceId, items) in group {
                if let items {
                    bySource[sourceId] = items
                } else {
                    failures += 1
                }
            }
        }

        guard currentGeneration == generation else { return }

        var seen = Set<String>()
        var merged: [Drama] = []
        for descriptor in descriptors {
            for drama in bySource[descriptor.id] ?? [] where seen.insert(drama.id).inserted {
                merged.append(drama)
            }
        }
        results = merged
        isSearching = false
        if merged.isEmpty && failures == descriptors.count {
            errorMessage = "所有站源都搜索失败，请检查网络后重试"
        }
    }

    nonisolated private static func search(descriptor: SourceDescriptor, keyword: String) async -> [Drama]? {
        await withTaskGroup(of: [Drama]?.self) { group in
            group.addTask {
                do {
                    let result = try await descriptor.provider.catalog(
                        category: "",
                        page: 1,
                        query: keyword
                    )
                    return result.items
                } catch {
                    return nil
                }
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: 15_000_000_000)
                return nil
            }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }
    }
}
