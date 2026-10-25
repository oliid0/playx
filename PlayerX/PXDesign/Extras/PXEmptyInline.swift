import SwiftUI
struct PXEmptyInline: View {
    var text: String
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "info.circle").font(.system(size: 10))
            Text(text).font(.system(size: 10, weight: .medium))
        }
        .foregroundStyle(PXTheme.textTertiary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 6)
    }
}
