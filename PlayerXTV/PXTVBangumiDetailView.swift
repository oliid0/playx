import SwiftUI

struct PXTVBangumiDetailView: View {
    @EnvironmentObject private var app: PXTVAppState
    @ObservedObject private var coordinator = PXBangumiCoordinator.shared
    let subjectID: Int
    @State private var subject: PXBangumiSubject?
    @State private var episodes: [PXBangumiEpisode] = []

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                if let subject {
                    HStack(alignment: .bottom, spacing: 24) {
                        PXRemoteImage(url: subject.imageURL, maxPixel: 600)
                            .frame(width: 210, height: 315)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        VStack(alignment: .leading, spacing: 10) {
                            Text(subject.displayTitle).font(PXFont.display(40)).foregroundStyle(PXTheme.textPrimary)
                            if let subtitle = subject.subtitle { Text(subtitle).font(.title3).foregroundStyle(PXTheme.textTertiary) }
                            HStack(spacing: 8) {
                                PXRatingBadge(rating: subject.rating?.score)
                                if let eps = subject.episodesText { PXTag(text: eps) }
                                if let year = subject.year { PXTag(text: String(year)) }
                            }
                            if let summary = subject.summary {
                                Text(summary).font(.body).foregroundStyle(PXTheme.textSecondary).lineSpacing(4).lineLimit(5)
                            }
                            HStack(spacing: 12) {
                                Button("想看") { Task { await coordinator.updateCollection(subjectID: subject.id, type: .wish) } }.buttonStyle(.card)
                                Button("在看") { Task { await coordinator.updateCollection(subjectID: subject.id, type: .doing) } }.buttonStyle(.card)
                                Button("看过") { Task { await coordinator.updateCollection(subjectID: subject.id, type: .done) } }.buttonStyle(.card)
                            }
                        }
                        Spacer()
                    }
                    if !episodes.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("章节").font(PXFont.title(26)).foregroundStyle(PXTheme.textPrimary)
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 12)], spacing: 12) {
                                ForEach(episodes) { episode in
                                    HStack {
                                        Text(String(format: "%02d", episode.number)).font(PXFont.mono(14)).foregroundStyle(PXTheme.textTertiary)
                                        Text(episode.displayName).font(.system(size: 16)).foregroundStyle(PXTheme.textPrimary)
                                        Spacer()
                                    }
                                    .padding(12)
                                    .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 9))
                                }
                            }
                        }
                    }
                } else {
                    PXTVLoadingView(text: "加载条目")
                }
            }
            .padding(.horizontal, 56)
            .padding(.top, 40)
            .padding(.bottom, 60)
        }
        .task {
            subject = await coordinator.subject(id: subjectID)
            episodes = await coordinator.episodes(subjectID: subjectID)
        }
    }
}
