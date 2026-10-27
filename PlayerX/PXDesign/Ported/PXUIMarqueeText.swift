import SwiftUI

struct PXUIMarqueeText: View {
    let text: String
    var font: Font = PXFont.caption(11)
    @State private var offset: CGFloat = 0
    @State private var animate = false

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(PXTheme.textSecondary)
            .lineLimit(1)
            .offset(x: offset)
            .clipped()
            .onAppear {
                guard text.count > 18 else { return }
                withAnimation(.linear(duration: 6).repeatForever(autoreverses: true)) {
                    offset = -30
                }
            }
    }
}
