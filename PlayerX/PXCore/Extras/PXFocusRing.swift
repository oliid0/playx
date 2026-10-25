import SwiftUI
struct PXFocusRing: ViewModifier {
    @FocusState private var focused: Bool
    func body(content: Content) -> some View { content }
}
