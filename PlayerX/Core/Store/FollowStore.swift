import Foundation

/// 想看 / 在看 / 已看，用户手动标记的那部分（"在看"大多数时候由 `HistoryStore` 里有没有
/// 播放记录自动推出来，不需要用户手动点，见 `FollowView`）。
enum FollowStatus: String, Codable {
    case planned   // 想看
    case watching  // 在看
    case watched   // 已看
}

struct FollowEntry: Codable, Identifiable, Hashable {
    var drama: Drama
    var status: FollowStatus
    var updatedAt: Date
    var id: String { drama.id }
}

@MainActor
final class FollowStore: ObservableObject {
    static let shared = FollowStore()

    @Published private(set) var entries: [FollowEntry] = []

    private let storageKey = "playerx.follow.v1"

    private init() { load() }

    func status(forDramaId dramaId: String) -> FollowStatus? {
        entries.first { $0.drama.id == dramaId }?.status
    }

    func setStatus(_ status: FollowStatus, for drama: Drama) {
        entries.removeAll { $0.drama.id == drama.id }
        entries.insert(FollowEntry(drama: drama, status: status, updatedAt: Date()), at: 0)
        save()
    }

    func remove(dramaId: String) {
        entries.removeAll { $0.drama.id == dramaId }
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([FollowEntry].self, from: data) else { return }
        entries = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
