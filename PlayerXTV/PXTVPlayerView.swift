import SwiftUI
import PillarboxPlayer

struct PXTVPlayerView: View {
    @Environment(\.dismiss) private var dismiss
    let request: PXTVPlaybackRequest
    @StateObject private var player = PillarboxPlayer.Player()

    init(request: PXTVPlaybackRequest) {
        self.request = request
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()
            SystemVideoView(player: player)
                .ignoresSafeArea()
            VStack(alignment: .leading, spacing: 3) {
                Text(request.title).font(.headline).foregroundStyle(.white)
                if let subtitle = request.subtitle {
                    Text(subtitle).font(.caption).foregroundStyle(.white.opacity(0.60))
                }
            }
            .padding(40)
            .allowsHitTesting(false)
        }
        .onAppear {
            player.currentItem = PillarboxPlayback.makeItem(
                url: request.url,
                headers: request.headers,
                identifier: request.url.absoluteString,
                title: request.title
            )
            player.becomeActive()
            player.play()
        }
        .onDisappear {
            player.pause()
            player.resignActive()
        }
        .onExitCommand { dismiss() }
    }
}
