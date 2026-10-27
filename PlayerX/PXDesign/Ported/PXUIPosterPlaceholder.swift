import SwiftUI

struct PXUIPosterPlaceholder: View {
    var width: CGFloat = 148
    var body: some View {
        RoundedRectangle(cornerRadius: PXTheme.posterRadius)
            .fill(PXTheme.surfaceMuted)
            .frame(width: width, height: width * 1.5)
            .overlay {
                Image(systemName: "film")
                    .font(.system(size: width * 0.18, weight: .light))
                    .foregroundStyle(PXTheme.textTertiary)
            }
    }
}
