import Foundation

#if os(iOS)
import UIKit
#endif

/// 播放期间阻止屏幕休眠；macOS 用 `ProcessInfo` 的活动声明，iOS 用 idle timer。
@MainActor
enum PXPlaybackWakeLock {
    #if os(macOS)
    private static var activity: NSObjectProtocol?
    #endif

    static func begin() {
        #if os(iOS)
        UIApplication.shared.isIdleTimerDisabled = true
        #elseif os(macOS)
        guard activity == nil else { return }
        activity = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiated, .idleSystemSleepDisabled],
            reason: "PlayerX video playback"
        )
        #endif
    }

    static func end() {
        #if os(iOS)
        UIApplication.shared.isIdleTimerDisabled = false
        #elseif os(macOS)
        if let activity {
            ProcessInfo.processInfo.endActivity(activity)
            self.activity = nil
        }
        #endif
    }
}
