import Foundation

/// 演员 / 导演。图片只存 TMDB 的相对路径，UI 统一经 `PXImageURL` 拼尺寸。
struct PXCastMember: Codable, Identifiable, Hashable, Sendable {
    var id: Int
    var name: String
    var character: String?
    var department: String?
    var job: String?
    var profilePath: String?
    var order: Int

    init(
        id: Int,
        name: String,
        character: String? = nil,
        department: String? = nil,
        job: String? = nil,
        profilePath: String? = nil,
        order: Int = 0
    ) {
        self.id = id
        self.name = name
        self.character = character
        self.department = department
        self.job = job
        self.profilePath = profilePath
        self.order = order
    }

    var roleText: String {
        if let character, !character.isEmpty { return character }
        if let job, !job.isEmpty { return job }
        return department ?? "演员"
    }

    var profileURL: URL? {
        PXImageURL.profile(profilePath, width: 300)
    }
}
