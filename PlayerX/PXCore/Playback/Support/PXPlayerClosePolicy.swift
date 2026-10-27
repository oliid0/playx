import Foundation

struct PXPlayerClosePolicy {
    var remembersProgress: Bool
    var hasNext: Bool
    var autoPlayNext: Bool

    func shouldConfirmClose(currentTime: Double, duration: Double) -> Bool {
        guard remembersProgress, duration > 60 else { return false }
        let progress = currentTime / duration
        return progress > 0.05 && progress < 0.95 && !(autoPlayNext && hasNext)
    }
}
