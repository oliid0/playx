import Foundation

enum PXUHomeLayoutMode: String, CaseIterable, Identifiable {
    case cinematic, compact
    var id: String { rawValue }
    var title: String { self == .cinematic ? "影院" : "紧凑" }
}
