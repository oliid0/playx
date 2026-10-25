import SwiftUI

struct PXLogoMark: View {
    var size: CGFloat = 38

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(PXTheme.accentGradient)
            Image(systemName: "play.fill")
                .font(.system(size: size * 0.38, weight: .black))
                .foregroundStyle(.black.opacity(0.82))
                .offset(x: size * 0.03)
        }
        .frame(width: size, height: size)
        .shadow(color: PXTheme.accent.opacity(0.32), radius: 10, y: 4)
    }
}
