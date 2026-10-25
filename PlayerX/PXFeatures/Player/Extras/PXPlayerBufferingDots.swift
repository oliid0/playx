import SwiftUI
struct PXPlayerBufferingDots: View {
    @State private var active = 0
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle().fill(.white.opacity(index == active ? 0.9 : 0.28))
                    .frame(width: 5, height: 5)
            }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 240_000_000)
                active = (active + 1) % 3
            }
        }
    }
}
