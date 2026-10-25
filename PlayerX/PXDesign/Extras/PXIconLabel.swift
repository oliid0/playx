import SwiftUI
struct PXIconLabel: View {
    var symbol: String
    var title: String
    var tint: Color = PXTheme.accent
    var body: some View {
        Label(title, systemImage: symbol)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(tint)
    }
}
