import Foundation

#if os(iOS)
import UIKit
#endif

/// 轻量触觉反馈。播放器的物理按键感主要靠它，不引入额外依赖。
@MainActor
enum Haptics {
    private static var isEnabled: Bool {
        PlaybackPreferences.shared.hapticsEnabled
    }

    static func light() {
        guard isEnabled else { return }
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }

    static func medium() {
        guard isEnabled else { return }
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }

    static func selection() {
        guard isEnabled else { return }
        #if os(iOS)
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }

    static func success() {
        guard isEnabled else { return }
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }
}
