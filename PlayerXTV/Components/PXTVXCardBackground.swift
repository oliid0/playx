import SwiftUI

struct PXTVXCardBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(PXTheme.surfaceMuted)
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(PXTheme.stroke, lineWidth: 0.7))
    }
}
