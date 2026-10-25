import SwiftUI

struct PXBangumiDetailView: View {
    let subjectID: Int
    let initial: PXBangumiSubject?
    @ObservedObject private var coordinator = PXBangumiCoordinator.shared
    @State private var subject: PXBangumiSubject?
    @State private var episodes: [PXBangumiEpisode] = []
    @State private var showSourceSearch = false

    var body: some View {
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    PXDetailBackdrop(
                        url: subject?.imageURL,
                        logoURL: nil,
                        title: subject?.displayTitle ?? initial?.displayTitle ?? "",
                        height: proxy.size.width > 800 ? 380 : 300
                    )
                    if let subject {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(alignment: .top, spacing: 14) {
                                PXRemoteImage(url: subject.imageURL, maxPixel: 500)
                                    .frame(width: 96, height: 144)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                VStack(alignment: .leading, spacing: 7) {
                                    Text(subject.displayTitle)
                                        .font(PXFont.title(24))
                                        .foregroundStyle(PXTheme.textPrimary)
                                    if let subtitle = subject.subtitle {
                                        Text(subtitle).font(.system(size: 11)).foregroundStyle(PXTheme.textTertiary)
                                    }
                                    HStack(spacing: 7) {
                                        if let score = subject.scoreText { PXRatingBadge(rating: Double(score)) }
                                        if let episodesText = subject.episodesText { PXTag(text: episodesText) }
                                        if let year = subject.year { PXTag(text: String(year)) }
                                    }
                                    if let summary = subject.summary, !summary.isEmpty {
                                        Text(summary)
                                            .font(.system(size: 11))
                                            .foregroundStyle(PXTheme.textSecondary)
                                            .lineSpacing(3)
                                            .lineLimit(5)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.horizontal, PXTheme.contentPadding)

                            if let interest = coordinator.collection(for: subject.id)?.type {
                                PXTag(text: "已标记 · \(interest.title)", tint: PXTheme.accent)
                                    .padding(.horizontal, PXTheme.contentPadding)
                            }

                            HStack(spacing: 8) {
                                Button {
                                    Task { await coordinator.updateCollection(subjectID: subject.id, type: .wish) }
                                } label: {
                                    Label("想看", systemImage: "heart")
                                }
                                .buttonStyle(PXSecondaryButtonStyle(compact: true))
                                Button {
                                    Task { await coordinator.updateCollection(subjectID: subject.id, type: .doing) }
                                } label: {
                                    Label("在看", systemImage: "play.circle")
                                }
                                .buttonStyle(PXSecondaryButtonStyle(compact: true))
                                Button {
                                    Task { await coordinator.updateCollection(subjectID: subject.id, type: .done) }
                                } label: {
                                    Label("看过", systemImage: "checkmark.circle")
                                }
                                .buttonStyle(PXSecondaryButtonStyle(compact: true))
                                Button {
                                    showSourceSearch = true
                                } label: {
                                    Label("找片", systemImage: "magnifyingglass")
                                }
                                .buttonStyle(PXPrimaryButtonStyle(compact: true))
                            }
                            .padding(.horizontal, PXTheme.contentPadding)

                            if !subject.displayTags.isEmpty {
                                FlowLayout(spacing: 6) {
                                    ForEach(subject.displayTags, id: \.self) { tag in
                                        PXTag(text: tag)
                                    }
                                }
                                .padding(.horizontal, PXTheme.contentPadding)
                            }

                            if !episodes.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    PXSectionHeader(title: "章节", subtitle: "\(episodes.count) 话", symbol: "list.number")
                                    ForEach(episodes) { episode in
                                        HStack(spacing: 10) {
                                            Text(String(format: "%02d", episode.number))
                                                .font(PXFont.mono(11))
                                                .foregroundStyle(PXTheme.textTertiary)
                                                .frame(width: 28)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(episode.displayName)
                                                    .font(.system(size: 12, weight: .medium))
                                                    .foregroundStyle(PXTheme.textPrimary)
                                                if let airdate = episode.airDate, !airdate.isEmpty {
                                                    Text(PXFormat.airDate(airdate))
                                                        .font(.system(size: 9))
                                                        .foregroundStyle(PXTheme.textTertiary)
                                                }
                                            }
                                            Spacer()
                                            Button {
                                                Task { await coordinator.markEpisode(episode, watched: true) }
                                            } label: {
                                                Image(systemName: "checkmark.circle")
                                                    .foregroundStyle(PXTheme.mint)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        .padding(.vertical, 7)
                                    }
                                }
                                .padding(.horizontal, PXTheme.contentPadding)
                            }
                        }
                    } else if coordinator.isLoading {
                        PXLoadingCard()
                    } else {
                        PXEmptyState(title: "条目加载失败", message: "请检查网络后重试。", actionTitle: "重试") {
                            Task { await load() }
                        }
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .background(PXPageBackground())
        .navigationTitle(subject?.displayTitle ?? "Bangumi")
        .pxInlineNavigationTitle()
        .task { await load() }
        .sheet(isPresented: $showSourceSearch) {
            PXSourceSearchSheet(query: subject?.displayTitle ?? initial?.displayTitle ?? "")
        }
    }

    private func load() async {
        if subject == nil { subject = initial }
        if let loaded = await coordinator.subject(id: subjectID) {
            subject = loaded
        }
        episodes = await coordinator.episodes(subjectID: subjectID)
    }
}
