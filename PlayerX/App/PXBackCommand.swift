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
