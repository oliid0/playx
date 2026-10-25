import SwiftUI
struct PXPlayerRateBadge: View {
    var rate: Double
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(String(format: "%.2gx", rate))
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.82))
                .padding(.horizontal, 8).frame(height: 24)
                .background(.black.opacity(0.28), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}
