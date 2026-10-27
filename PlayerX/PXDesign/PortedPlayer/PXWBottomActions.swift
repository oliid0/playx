import SwiftUI

struct PXWBottomActions<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        HStack(spacing: 22) { content }
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(PXTheme.textPrimary)
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(PXTheme.stroke))
    }
}
