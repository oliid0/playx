import SwiftUI

struct PXShimmer: View {
    @State private var phase: CGFloat = -1

    var body: some View {
        GeometryReader { proxy in
            LinearGradient(
                colors: [
                    Color.white.opacity(0.03),
                    Color.white.opacity(0.11),
                    Color.white.opacity(0.03),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: proxy.size.width * 1.7)
            .offset(x: proxy.size.width * phase)
            .onAppear {
                withAnimation(.linear(duration: 1.35).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
        }
        .clipped()
    }
}

struct PXSkeletonPoster: View {
    var width: CGFloat = PXTheme.posterWidth
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: PXTheme.posterRadius, style: .continuous)
                .fill(PXTheme.surface)
                .aspectRatio(2 / 3, contentMode: .fit)
                .overlay(PXShimmer().clipShape(RoundedRectangle(cornerRadius: PXTheme.posterRadius)))
                .frame(width: width)
            RoundedRectangle(cornerRadius: 4).fill(PXTheme.surface).frame(width: width * 0.82, height: 11)
            RoundedRectangle(cornerRadius: 4).fill(PXTheme.surfaceMuted).frame(width: width * 0.55, height: 9)
        }
        .frame(width: width, alignment: .leading)
    }
}
