import Foundation

struct PXPlayerHUDVisibility {
    var autoHideSeconds: Double
    var isLocked = false
    var isPaused = false

    func shouldAutoHide(afterInteraction: Bool) -> Bool {
        guard !isLocked, !isPaused, autoHideSeconds > 0, afterInteraction else { return false }
        return true
    }
}
