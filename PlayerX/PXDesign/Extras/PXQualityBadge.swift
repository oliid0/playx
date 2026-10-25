import SwiftUI
struct PXQualityBadge: View {
    var quality: Int
    var body: some View {
        Text(quality >= 2160 ? "4K" : quality >= 1080 ? "1080P" : quality >= 720 ? "720P" : "\(quality)P")
            .font(.system(size: 8, weight: .heavy))
            .foregroundStyle(.black.opacity(0.82))
            .padding(.horizontal, 5).frame(height: 16)
            .background(PXTheme.accent, in: RoundedRectangle(cornerRadius: 3))
    }
}
