import SwiftUI

#if os(iOS)
import UIKit
typealias PlatformImage = UIImage
typealias PlatformColor = UIColor
#elseif os(macOS)
import AppKit
typealias PlatformImage = NSImage
typealias PlatformColor = NSColor
#endif

// MARK: - 图片 / 颜色跨平台适配
//
// 播放器、封面、缓存三处原本都直接写 UIImage。改成 PlatformImage +
// Image(platformImage:) 之后，iOS/iPadOS 与 macOS 共用同一套视图代码。

extension Image {
    init(platformImage: PlatformImage) {
        #if os(iOS)
        self.init(uiImage: platformImage)
        #else
        self.init(nsImage: platformImage)
        #endif
    }
}

extension Color {
    init(platformColor: PlatformColor) {
        #if os(iOS)
        self.init(uiColor: platformColor)
        #else
        self.init(nsColor: platformColor)
        #endif
    }
}

enum Platform {
    /// 封面下采样用的屏幕 scale。macOS 没有 UIScreen.main。
    static var screenScale: CGFloat {
        #if os(iOS)
        UIScreen.main.scale
        #else
        NSScreen.main?.backingScaleFactor ?? 2
        #endif
    }

    static var isMac: Bool {
        #if os(macOS)
        true
        #else
        false
        #endif
    }

    static var isPad: Bool {
        #if os(iOS)
        UIDevice.current.userInterfaceIdiom == .pad
        #else
        false
        #endif
    }
}

// MARK: - 导航 / 工具栏 / 键盘的跨平台修饰符

extension View {
    @ViewBuilder
    func appInlineNavigationTitle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    @ViewBuilder
    func appLargeNavigationTitle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.large)
        #else
        self
        #endif
    }

    @ViewBuilder
    func appTransparentNavigationChrome() -> some View {
        #if os(iOS)
        self
            .toolbarBackground(.hidden, for: .navigationBar)
        #else
        self
        #endif
    }

    @ViewBuilder
    func appHideNavigationBar() -> some View {
        #if os(iOS)
        self.toolbar(.hidden, for: .navigationBar)
        #else
        self
        #endif
    }

    /// 播放器全屏时隐藏状态栏 / Home Indicator（仅 iOS/iPadOS 有这些系统 UI）。
    @ViewBuilder
    func appPlayerSystemChrome() -> some View {
        #if os(iOS)
        self
            .statusBar(hidden: true)
            .persistentSystemOverlays(.hidden)
        #else
        self
        #endif
    }

    /// iPhone 竖屏隐藏导航栏，让首页自定义 header 顶到状态栏；iPad 常规宽度/分屏保留
    /// 导航栏，否则会丢掉系统侧边栏的显示/收起按钮。
    func appHideNavigationBarOnCompact() -> some View {
        modifier(HideNavigationBarOnCompactModifier())
    }

    /// 搜索框关闭自动大写/纠错（iOS 键盘专有；macOS 没有这些修饰符）。
    @ViewBuilder
    func appSearchFieldBehavior() -> some View {
        #if os(iOS)
        self
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
        #else
        self
        #endif
    }

    /// PIN 输入用数字键盘；macOS 无 keyboardType。
    @ViewBuilder
    func appNumericKeyboard() -> some View {
        #if os(iOS)
        self.keyboardType(.numberPad)
        #else
        self
        #endif
    }

    /// macOS 的播放器 Sheet 需要显式窗口尺寸，否则会缩成内容最小尺寸。
    @ViewBuilder
    func appPlayerWindowFrame() -> some View {
        #if os(macOS)
        self
            .frame(minWidth: 960, minHeight: 600)
        #else
        self
        #endif
    }

    /// iOS 的 sheet 用系统 detent；macOS 用固定窗口尺寸。
    @ViewBuilder
    func appPlayerEpisodesSheet() -> some View {
        #if os(iOS)
        self
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        #else
        self
            .frame(minWidth: 560, minHeight: 520)
        #endif
    }

    @ViewBuilder
    func appPlayerInfoSheet() -> some View {
        #if os(iOS)
        self
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        #else
        self
            .frame(minWidth: 520, minHeight: 480)
        #endif
    }

    /// 详情页播放器：iOS 全屏 cover；macOS 用大尺寸 sheet，避免在窗口里再弹一个全屏窗口。
    func appPlayerPresentation<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        #if os(iOS)
        return fullScreenCover(item: item, content: content)
        #else
        return sheet(item: item) { value in
            content(value)
                .frame(minWidth: 1_000, minHeight: 620)
        }
        #endif
    }
}

extension ToolbarItemPlacement {
    /// iOS 的导航栏右侧；macOS 的主操作区。
    static var appTrailing: ToolbarItemPlacement {
        #if os(iOS)
        .navigationBarTrailing
        #else
        .primaryAction
        #endif
    }

    static var appConfirmation: ToolbarItemPlacement {
        #if os(iOS)
        .confirmationAction
        #else
        .primaryAction
        #endif
    }

    static var appCancellation: ToolbarItemPlacement {
        #if os(iOS)
        .cancellationAction
        #else
        .cancellationAction
        #endif
    }
}

private struct HideNavigationBarOnCompactModifier: ViewModifier {
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var sizeClass
    #endif

    @ViewBuilder
    func body(content: Content) -> some View {
        #if os(iOS)
        if Platform.isPad && sizeClass == .regular {
            content
        } else {
            content.toolbar(.hidden, for: .navigationBar)
        }
        #else
        content
        #endif
    }
}

// MARK: - 指针悬停

private struct HoverLiftModifier: ViewModifier {
    @State private var hovering = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(hovering ? 1.018 : 1)
            .shadow(color: .black.opacity(hovering ? 0.28 : 0), radius: hovering ? 16 : 0, y: hovering ? 8 : 0)
            .animation(AppTheme.gentleSpring, value: hovering)
            .onHover { hovering = $0 }
    }
}

extension View {
    /// iPad 指针 / Mac 鼠标悬停时的轻微抬升；触屏设备没有 hover，视觉无变化。
    func appHoverLift() -> some View {
        modifier(HoverLiftModifier())
    }
}
