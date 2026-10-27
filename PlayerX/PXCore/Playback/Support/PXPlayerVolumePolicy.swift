import Foundation

struct PXPlayerVolumePolicy {
    static func clamped(_ volume: Double) -> Double { min(max(volume, 0), 1) }
    static func isMuted(_ volume: Double) -> Bool { volume < 0.01 }
    static func label(_ volume: Double) -> String { "\(Int(clamped(volume) * 100))%" }
}
