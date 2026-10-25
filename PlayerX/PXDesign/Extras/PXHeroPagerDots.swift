import SwiftUI
struct PXHeroPagerDots: View {
    var count: Int
    var index: Int
    var onSelect: (Int) -> Void
    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<count, id: \.self) { idx in
                Button { onSelect(idx) } label: {
                    Capsule().fill(idx == index ? PXTheme.accent : Color.white.opacity(0.24))
                        .frame(width: idx == index ? 20 : 6, height: 4)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
