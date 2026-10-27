import Foundation
import AVFoundation

#if os(iOS) || os(tvOS)
import UIKit
#endif

@MainActor
enum PXPlaybackAudioSession {
    static func activate() {
        #if os(iOS) || os(tvOS)
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .moviePlayback, options: [.allowAirPlay, .allowBluetooth])
        try? session.setActive(true)
        #endif
    }

    static func deactivate() {
        #if os(iOS) || os(tvOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        #endif
    }
}
