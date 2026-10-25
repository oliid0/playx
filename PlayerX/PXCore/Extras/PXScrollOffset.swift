import SwiftUI
struct PXScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}
extension View {
    func pxTrackScrollOffset() -> some View {
        background(GeometryReader { proxy in
            Color.clear.preference(key: PXScrollOffsetKey.self, value: proxy.frame(in: .named("px-scroll")).minY)
        })
    }
}
