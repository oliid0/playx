import SwiftUI
import AVFoundation
import AVKit
import QuartzCore

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// 原生画面层。`AVPlayerLayer` 直接挂在平台 View 上，由 AVFoundation 负责解码与显示；
/// 相比把 `AVPlayerViewController` 的控件关掉再套一层 SwiftUI，自己持有 layer 的好处是
/// 可以把同一个 layer 交给 `AVPictureInPictureController`，画中画用的是系统原生实现，
/// 不是另开一路播放。
struct PlayerLayerView: View {
    let player: AVPlayer
    let onLayerReady: (AVPlayerLayer) -> Void

    var body: some View {
        #if os(iOS)
        IOSPlayerLayer(player: player, onLayerReady: onLayerReady)
        #else
        MacPlayerLayer(player: player, onLayerReady: onLayerReady)
        #endif
    }
}

// MARK: - iOS / iPadOS

#if os(iOS)
private struct IOSPlayerLayer: UIViewRepresentable {
    let player: AVPlayer
    let onLayerReady: (AVPlayerLayer) -> Void

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> PlayerHostView {
        let view = PlayerHostView()
        view.backgroundColor = .black
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspect
        context.coordinator.didSendLayer = false

        DispatchQueue.main.async {
            guard !context.coordinator.didSendLayer else { return }
            context.coordinator.didSendLayer = true
            onLayerReady(view.playerLayer)
        }
        return view
    }

    func updateUIView(_ uiView: PlayerHostView, context: Context) {
        if uiView.playerLayer.player !== player {
            uiView.playerLayer.player = player
        }
        uiView.playerLayer.videoGravity = .resizeAspect
    }

    final class Coordinator {
        var didSendLayer = false
    }
}

final class PlayerHostView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }

    var playerLayer: AVPlayerLayer {
        // layerClass 已固定为 AVPlayerLayer，这里的强转不会失败。
        layer as! AVPlayerLayer
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}
#endif

// MARK: - macOS

#if os(macOS)
private struct MacPlayerLayer: NSViewRepresentable {
    let player: AVPlayer
    let onLayerReady: (AVPlayerLayer) -> Void

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> PlayerHostNSView {
        let view = PlayerHostNSView(frame: .zero)
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspect
        context.coordinator.didSendLayer = false

        DispatchQueue.main.async {
            guard !context.coordinator.didSendLayer else { return }
            context.coordinator.didSendLayer = true
            onLayerReady(view.playerLayer)
        }
        return view
    }

    func updateNSView(_ nsView: PlayerHostNSView, context: Context) {
        if nsView.playerLayer.player !== player {
            nsView.playerLayer.player = player
        }
        nsView.playerLayer.videoGravity = .resizeAspect
    }

    final class Coordinator {
        var didSendLayer = false
    }
}

final class PlayerHostNSView: NSView {
    let playerLayer = AVPlayerLayer()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer = playerLayer
        playerLayer.videoGravity = .resizeAspect
    }

    required init?(coder: NSCoder) {
        fatalError("PlayerHostNSView is programmatic-only")
    }

    override func layout() {
        super.layout()
        playerLayer.frame = bounds
    }
}
#endif

// MARK: - AirPlay 路由

/// 系统 AirPlay 路由按钮。iOS 用 `AVRoutePickerView`，macOS 也使用 AVKit 的同名视图，
/// 音频路由、隔空播放、镜像的可用性完全交给系统判断，不自己列设备。
struct AirPlayRouteButton: View {
    var tint: PlatformColor = .white

    var body: some View {
        #if os(iOS)
        IOSRoutePicker(tint: tint)
        #else
        MacRoutePicker()
        #endif
    }
}

#if os(iOS)
private struct IOSRoutePicker: UIViewRepresentable {
    let tint: UIColor

    func makeUIView(context: Context) -> AVRoutePickerView {
        let view = AVRoutePickerView()
        view.backgroundColor = .clear
        view.tintColor = tint
        view.activeTintColor = UIColor(AppTheme.brand)
        view.prioritizesVideoDevices = true
        return view
    }

    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {
        uiView.tintColor = tint
        uiView.activeTintColor = UIColor(AppTheme.brand)
    }
}
#else
private struct MacRoutePicker: NSViewRepresentable {
    func makeNSView(context: Context) -> AVRoutePickerView {
        let view = AVRoutePickerView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }

    func updateNSView(_ nsView: AVRoutePickerView, context: Context) {}
}
#endif
