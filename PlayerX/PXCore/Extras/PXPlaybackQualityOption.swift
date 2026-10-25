import Foundation
struct PXPlaybackQualityOption: Identifiable, Hashable {
    var value: Int
    var title: String
    var detail: String?
    var id: Int { value }
    static let auto = PXPlaybackQualityOption(value: 0, title: "自动", detail: "跟随网络与站源")
    static let all: [PXPlaybackQualityOption] = [
        auto,
        .init(value: 720, title: "720P", detail: "省流量"),
        .init(value: 1080, title: "1080P", detail: "推荐"),
        .init(value: 2160, title: "4K", detail: "高码率"),
    ]
}
