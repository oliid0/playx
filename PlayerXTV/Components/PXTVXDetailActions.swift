import SwiftUI

struct PXTVXDetailActions: View {
    let onPlay: () -> Void
    let onFollow: () -> Void
    var body: some View {
        HStack(spacing: 14) {
            Button("播放", systemImage: "play.fill", action: onPlay).buttonStyle(.card)
            Button("追剧", systemImage: "plus", action: onFollow).buttonStyle(.card)
        }
    }
}
