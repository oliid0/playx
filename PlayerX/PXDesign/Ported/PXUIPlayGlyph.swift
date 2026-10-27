import SwiftUI

struct PXUIPlayGlyph: View {
    var size: CGFloat = 46
    var body: some View {
        Image(systemName: "play.fill")
            .font(.system(size: size * 0.34, weight: .bold))
            .foregroundStyle(PXTheme.textPrimary)
            .frame(width: size, height: size)
            .background(.ultraThinMaterial, in: Circle())
            .overlay(Circle().strokeBorder(PXTheme.strokeStrong, lineWidth: 0.8))
    }
}
