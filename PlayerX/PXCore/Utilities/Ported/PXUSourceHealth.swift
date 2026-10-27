import Foundation

struct PXUSourceHealth: Identifiable {
    let id: String
    var name: String
    var latencyMilliseconds: Int?
    var isReachable: Bool
    var lastChecked: Date?
    var statusText: String {
        if !isReachable { return "不可达" }
        if let latencyMilliseconds { return "\(latencyMilliseconds) ms" }
        return "可用"
    }
}
