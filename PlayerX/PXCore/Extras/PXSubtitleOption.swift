import Foundation
struct PXSubtitleOption: Identifiable, Hashable {
    var id: String
    var title: String
    var language: String?
    var isExternal: Bool
    var isSelected: Bool
    static let off = PXSubtitleOption(id: "off", title: "关闭字幕", language: nil, isExternal: false, isSelected: true)
}
