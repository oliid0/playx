import SwiftUI
struct PXDetailTrailerRail: View {
    var videos: [PXVideoClip]
    var body: some View {
        if !videos.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("预告片").font(PXFont.section(16)).foregroundStyle(PXTheme.textPrimary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(videos) { video in
                            if let url = video.youtubeURL {
                                Link(destination: url) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8).fill(PXTheme.surface)
                                            Image(systemName: "play.fill").foregroundStyle(PXTheme.accent)
                                        }
                                        .frame(width: 176, height: 99)
                                        Text(video.name).font(.system(size: 9)).foregroundStyle(PXTheme.textSecondary).lineLimit(1).frame(width: 176, alignment: .leading)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }
}
