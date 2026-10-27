import CoreGraphics

enum PXPlayerAspectRatio: String, CaseIterable, Identifiable {
    case fit
    case fill
    case ratio16x9
    case ratio4x3
    case original

    var id: String { rawValue }
    var title: String {
        switch self {
        case .fit: "适应"
        case .fill: "填充"
        case .ratio16x9: "16:9"
        case .ratio4x3: "4:3"
        case .original: "原始"
        }
    }
}
