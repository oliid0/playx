import Foundation
import AVFoundation

@MainActor
final class PXPlaybackInterruptionObserver {
    private var token: NSObjectProtocol?
    var onInterrupted: (() -> Void)?
    var onResumed: (() -> Void)?

    func start() {
        #if os(iOS) || os(tvOS)
        token = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] note in
            guard let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }
            Task { @MainActor in
                switch type {
                case .began: self?.onInterrupted?()
                case .ended: self?.onResumed?()
                @unknown default: break
                }
            }
        }
        #endif
    }

    func stop() {
        if let token { NotificationCenter.default.removeObserver(token) }
        token = nil
    }
}
