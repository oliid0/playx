import SwiftUI
struct PXCounter: View {
    var value: Int
    var total: Int?
    var body: some View {
        HStack(spacing: 3) {
            Text("\(value)").font(PXFont.mono(10, weight: .bold)).foregroundStyle(PXTheme.textPrimary)
            if let total { Text("/ \(total)").font(PXFont.mono(9)).foregroundStyle(PXTheme.textTertiary) }
        }
    }
}
