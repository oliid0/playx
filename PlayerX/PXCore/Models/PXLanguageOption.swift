import Foundation

struct PXLanguageOption: Identifiable, Hashable {
    var code: String
    var title: String
    var id: String { code }

    static let all: [PXLanguageOption] = [
        .init(code: "zh-CN", title: "简体中文"),
        .init(code: "zh-TW", title: "繁體中文"),
        .init(code: "ja-JP", title: "日本語"),
        .init(code: "en-US", title: "English"),
        .init(code: "ko-KR", title: "한국어"),
    ]
}
