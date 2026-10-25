import Foundation
struct PXServiceHealth: Identifiable {
    var id: String { name }
    var name: String
    var state: PXIntegrationState
    var detail: String?
}
