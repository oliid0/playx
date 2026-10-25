import Foundation
enum PXIntegrationState: Equatable {
    case disabled
    case notConfigured
    case connecting
    case ready
    case failed(String)
    var title: String {
        switch self {
        case .disabled: "已关闭"
        case .notConfigured: "未配置"
        case .connecting: "连接中"
        case .ready: "可用"
        case .failed: "异常"
        }
    }
    var isReady: Bool { self == .ready }
}
