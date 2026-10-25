import SwiftUI
struct PXPlayerQualityBadge: View {
    var text: String
    var body: some View {
        Text(text)
            .font(.system(size: 8, weight: .heavy))
            .foregroundStyle(PXTheme.accent)
            .padding(.horizontal, 5).frame(height: 16)
            .background(.black.opacity(0.30), in: RoundedRectangle(cornerRadius: 3))
    }
}
