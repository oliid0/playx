import SwiftUI

struct PXUILoadingDots: View {
    @State private var active = 0
    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { index in
                Circle().fill(PXTheme.textSecondary)
                    .frame(width: 5, height: 5)
                    .opacity(active == index ? 1 : 0.35)
            }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 260_000_000)
                active = (active + 1) % 3
            }
        }
    }
}
