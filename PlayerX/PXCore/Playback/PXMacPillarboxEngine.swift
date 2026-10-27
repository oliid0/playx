#if os(macOS)
import AVFoundation
import SwiftUI

/// macOS 上的 Pillarbox 兼容内核。
///
/// 上游 `PillarboxPlayer` 的 Package 只声明 iOS/tvOS；但 mac（Apple Silicon）
///  playback 本身完全由 AVFoundation 承担。这里保留 Pillarbox 的内核身份、队列式
///  AVPlayer 承载和系统播放能力，让 mac 用户仍可在设置里选择 Pillarbox，而不是
/// 显示为不可用。实际解码/字幕路径与原生 AVPlayer 内核一致。
@MainActor
final class PXMacPillarboxEngine: PXAVPlayerEngine {
    override class var kind: PXPlayerEngineKind { .pillarbox }

    override var supportsExternalSubtitles: Bool { true }

    override func setBackgroundPlayback(_ active: Bool) {
        // macOS 上 App 失焦时 AVPlayer 可继续播放；后台音频由系统会话控制。
    }
}
#endif
