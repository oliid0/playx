import SwiftUI

extension Notification.Name {
    static let playerXNavigationBack = Notification.Name("playerx.navigation.back")
}

struct PXBackCommandModifier: ViewModifier {
    @Environment(\.dismiss) private var dismiss
    func body(content: Content) -> some View {
        content.onReceive(NotificationCenter.default.publisher(for: .playerXNavigationBack)) { _ in
            dismiss()
        }
    }
}

extension View {
    func pxBackCommand() -> some View { modifier(PXBackCommandModifier()) }
}

#if os(macOS)
import AppKit

struct PXWindowDragArea: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView { DragView() }
    func updateNSView(_ nsView: NSView, context: Context) {}

    private final class DragView: NSView {
        override func mouseDown(with event: NSEvent) {
            window?.performDrag(with: event)
            super.mouseDown(with: event)
        }
    }
}
#endif
