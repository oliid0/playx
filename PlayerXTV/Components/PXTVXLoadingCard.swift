import SwiftUI

struct PXTVXLoadingCard: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(PXTheme.surfaceMuted)
            .frame(width: 180, height: 270)
            .overlay(ProgressView())
    }
}
