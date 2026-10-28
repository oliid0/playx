import Foundation

/// 播放进度记录，一部剧一条（存"最近看到哪一集、看到第几秒"，不是每集一条）。
/// 纯本地存储（`UserDefaults`），不走 Go 核心——这块数据 Go 侧完全不管，和调研报告里
/// Dart 版"本地单 JSON 文档"的思路一致，只是简化成了标准 Codable + UserDefaults，
/// 没有照搬它那套版本号/备份/回滚机制（YAGNI，先不需要）。
struct HistoryEntry: Codable, Identifiable, Hashable {
    var drama: Drama
    var chapter: Chapter
    var episodeIndex: Int
    var position: Double
    var duration: Double
    var updatedAt: Date
    var id: String { drama.id }
    var progress: Double { duration > 0 ? min(max(position / duration, 0), 1) : 0 }
}

@MainActor
final class HistoryStore: ObservableObject {
    static let shared = HistoryStore()

    @Published private(set) var entries: [HistoryEntry] = []

    private let storageKey = "playerx.history.v1"
    private let limit = 300

    private init() { load() }

    func entry(forDramaId dramaId: String) -> HistoryEntry? {
        entries.first { $0.drama.id == dramaId }
    }

    func record(drama: Drama, chapter: Chapter, episodeIndex: Int, position: Double, duration: Double) {
        guard duration > 0 else { return }
        entries.removeAll { $0.drama.id == drama.id }
        let entry = HistoryEntry(drama: drama, chapter: chapter, episodeIndex: episodeIndex,
                                  position: position, duration: duration, updatedAt: Date())
        entries.insert(entry, at: 0)
        if entries.count > limit {
            entries.removeLast(entries.count - limit)
        }
        save()
    }

    func remove(dramaId: String) {
        entries.removeAll { $0.drama.id == dramaId }
        save()
    }

    func clearAll() {
        entries.removeAll()
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([HistoryEntry].self, from: data) else { return }
        entries = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
