import SwiftUI

struct PXUISourceKindGlyph: View {
    let kind: PXSourceKind
    var body: some View {
        Image(systemName: kind.symbol)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(PXTheme.textSecondary)
            .frame(width: 26, height: 26)
            .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 7))
    }
}
