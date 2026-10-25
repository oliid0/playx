import SwiftUI
struct PXPlayerLockOverlay: View {
    var onUnlock: () -> Void
    var body: some View {
        VStack {
            Spacer()
            Button(action: onUnlock) {
                Label("解锁控制", systemImage: "lock.open")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14).frame(height: 34)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.bottom, 30)
        }
    }
}
