import SwiftUI

struct PXWLockGlyph: View {
    let locked: Bool
    var body: some View {
        Image(systemName: locked ? "lock.fill" : "lock.open")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(PXTheme.textSecondary)
            .frame(width: 34, height: 34)
            .background(PXTheme.surfaceMuted, in: Circle())
    }
}
