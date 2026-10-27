import Foundation

enum PXUNetworkQuality: String, CaseIterable {
    case excellent, good, fair, poor, offline
    var title: String {
        switch self {
        case .excellent: "极佳"
        case .good: "良好"
        case .fair: "一般"
        case .poor: "较差"
        case .offline: "离线"
        }
    }
}
