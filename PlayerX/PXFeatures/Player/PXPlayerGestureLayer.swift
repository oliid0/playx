import SwiftUI

struct PXPlayerGestureLayer: View {
    @ObservedObject var model: PXPlayerModel
    @State private var dragStart: Double?
    @State private var dragTarget: Double?

    var body: some View {
        GeometryReader { proxy in
            Color.black.opacity(0.001)
                .contentShape(Rectangle())
                .onTapGesture {
                    if model.controlsVisible { model.hideControls() } else { model.revealsControls() }
                }
                .gesture(
                    DragGesture(minimumDistance: 24)
                        .onChanged { value in
                            guard PXPlayerPreferences.shared.dragSeek, model.duration > 0 else { return }
                            if abs(value.translation.width) <= abs(value.translation.height) { return }
                            if dragStart == nil {
                                dragStart = model.currentTime
                                model.revealsControls()
                            }
                            let range = min(max(model.duration, 60), 600)
                            let delta = Double(value.translation.width / max(proxy.size.width, 1)) * range
                            dragTarget = min(max((dragStart ?? 0) + delta, 0), max(model.duration - 0.2, 0))
                        }
                        .onEnded { value in
                            if abs(value.translation.height) > 70,
                               abs(value.translation.height) > abs(value.translation.width) * 1.4 {
                                if value.translation.height < 0 { model.playNext() } else { model.playPrevious() }
                            } else if let target = dragTarget {
                                model.seek(to: target)
                            }
                            dragStart = nil
                            dragTarget = nil
                        }
                )

            if let target = dragTarget {
                HStack(spacing: 8) {
                    Image(systemName: "goforward")
                    Text(PXFormat.time(target)).font(PXFont.mono(14))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .frame(height: 42)
                .background(.ultraThinMaterial, in: Capsule())
                .position(x: proxy.size.width / 2, y: proxy.size.height * 0.78)
                .allowsHitTesting(false)
            }
        }
        .ignoresSafeArea()
    }
}
