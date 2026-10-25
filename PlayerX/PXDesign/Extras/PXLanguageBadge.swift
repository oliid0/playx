import SwiftUI
struct PXLanguageBadge: View {
    var code: String?
    var body: some View {
        if let code, !code.isEmpty {
            Text(code.uppercased()).font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(PXTheme.textTertiary)
                .padding(.horizontal, 5).frame(height: 16)
                .background(PXTheme.surface, in: Capsule())
        }
    }
}
