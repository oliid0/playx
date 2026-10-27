import SwiftUI

struct PXUISelectionCheck: View {
    let selected: Bool
    var body: some View {
        Image(systemName: selected ? "checkmark.circle.fill" : "circle")
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(selected ? PXTheme.accent : PXTheme.textTertiary)
    }
}
