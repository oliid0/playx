import SwiftUI

struct PXWPiPButton: View {
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: "pip.enter").font(.system(size: 13, weight: .semibold)).foregroundStyle(PXTheme.textSecondary)
        }
        .buttonStyle(.plain)
    }
}
