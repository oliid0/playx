import SwiftUI

#if os(iOS) || os(tvOS)
import UIKit
typealias PXPlatformImage = UIImage
typealias PXPlatformView = UIView
#elseif os(macOS)
import AppKit
typealias PXPlatformImage = NSImage
typealias PXPlatformView = NSView
#endif

extension Image {
    init(pxImage: PXPlatformImage) {
        #if os(macOS)
        self.init(nsImage: pxImage)
        #else
        self.init(uiImage: pxImage)
        #endif
    }
}

enum PXPlatform {
    static var isTV: Bool {
        #if os(tvOS)
        true
        #else
        false
        #endif
    }

    static var isMac: Bool {
        #if os(macOS)
        true
        #else
        false
        #endif
    }

    static var screenScale: CGFloat {
        #if os(iOS) || os(tvOS)
        UIScreen.main.scale
        #else
        NSScreen.main?.backingScaleFactor ?? 2
        #endif
    }
}

extension View {
    @ViewBuilder
    func pxInlineNavigationTitle() -> some View {
        #if os(iOS)
        navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    @ViewBuilder
    func pxHiddenNavigationBar() -> some View {
        #if os(iOS)
        toolbar(.hidden, for: .navigationBar)
        #else
        self
        #endif
    }

    @ViewBuilder
    func pxTransparentNavigation() -> some View {
        #if os(iOS)
        toolbarBackground(.hidden, for: .navigationBar)
        #else
        self
        #endif
    }

    @ViewBuilder
    func pxHoverLift() -> some View {
        #if os(macOS) || os(iOS)
        modifier(PXHoverLiftModifier())
        #else
        self
        #endif
    }

    @ViewBuilder
    func pxPlayerSystemChrome() -> some View {
        #if os(iOS)
        self
            .statusBar(hidden: true)
            .persistentSystemOverlays(.hidden)
        #else
        self
        #endif
    }

    @ViewBuilder
    func pxNumericKeyboard() -> some View {
        #if os(iOS)
        keyboardType(.numberPad)
        #else
        self
        #endif
    }
}

#if os(macOS) || os(iOS)
private struct PXHoverLiftModifier: ViewModifier {
    @State private var hovering = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(hovering ? 1.015 : 1)
            .shadow(color: .black.opacity(hovering ? 0.30 : 0.12), radius: hovering ? 18 : 8, y: hovering ? 9 : 4)
            .animation(PXTheme.spring, value: hovering)
            .onHover { hovering = $0 }
    }
}
#endif
