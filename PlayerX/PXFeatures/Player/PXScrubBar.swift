import SwiftUI

struct PXScrubBar: View {
    @ObservedObject var model: PXPlayerModel
    @State private var isDragging = false
    @State private var dragValue: Double = 0

    var body: some View {
        GeometryReader { proxy in
            let value = isDragging ? dragValue : model.currentTime
            let fraction = model.duration > 0 ? min(max(value / model.duration, 0), 1) : 0
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.22)).frame(height: 4)
                Capsule().fill(PXTheme.accent)
                    .frame(width: proxy.size.width * fraction, height: 4)
                if model.chapters.count > 1 {
                    ForEach(1..<model.chapters.count, id: \.self) { index in
                        Capsule()
                            .fill(.black.opacity(0.42))
                            .frame(width: 1.2, height: 6)
                            .offset(x: proxy.size.width * CGFloat(index) / CGFloat(model.chapters.count))
                    }
                }
                Circle()
                    .fill(.white)
                    .frame(width: isDragging ? 13 : 9, height: isDragging ? 13 : 9)
                    .offset(x: max(0, proxy.size.width * fraction - 4.5))
                    .shadow(color: .black.opacity(0.4), radius: 3)
            }
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        isDragging = true
                        let raw = Double(gesture.location.x / max(proxy.size.width, 1)) * model.duration
                        dragValue = min(max(raw, 0), model.duration)
                    }
                    .onEnded { _ in
                        model.seek(to: dragValue)
                        isDragging = false
                    }
            )
            .accessibilityElement()
            .accessibilityLabel("播放进度")
            .accessibilityValue(PXFormat.time(value))
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: model.skipForward()
                case .decrement: model.skipBackward()
                @unknown default: break
                }
            }
        }
        .frame(height: 24)
    }
}
