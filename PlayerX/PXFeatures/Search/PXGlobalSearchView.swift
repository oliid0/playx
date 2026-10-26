import SwiftUI

struct PXGlobalSearchView: View {
    var embedded: Bool = false
    @EnvironmentObject private var app: PXAppState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var model = PXSearchViewModel()
    @State private var preview: PXMediaRecommendation?
    @FocusState private var focused: Bool
    @AppStorage("playerx.search.recent.v1") private var recentRaw = ""

    init(embedded: Bool = false) {
        self.embedded = embedded
    }

    @ViewBuilder
    var body: some View {
        if embedded {
            searchContent
        } else {
            NavigationStack { searchContent }
                .preferredColorScheme(.dark)
        }
    }

    private var searchContent: some View {
        VStack(spacing: 0) {
            PXSearchField(text: $model.query, prompt: "搜索电影、剧集、动漫、演员") {
                saveRecent(model.query)
                model.submit()
            }
            .focused($focused)
            .padding(.horizontal, PXTheme.contentPadding)
            .padding(.top, 8)
            scopeBar
            content
        }
        .background(PXPageBackground())
        .navigationTitle("搜索")
        .pxInlineNavigationTitle()
        .toolbar {
            if !embedded {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
        .task { focused = true }
        .sheet(item: $preview) { item in
            PXMediaPreviewSheet(recommendation: item)
        }
    }

    private var scopeBar: some View {
        HStack(spacing: 7) {
            ForEach(PXSearchScope.allCases) { scope in
                Button {
                    model.scope = scope
                    if !model.query.isEmpty { model.submit() }
                } label: {
                    PXChip(title: scope.title, selected: model.scope == scope)
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, PXTheme.contentPadding)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var content: some View {
        if model.isSearching {
            PXLoadingCard()
            Spacer()
        } else if model.results.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                PXSectionHeader(title: "最近搜索", subtitle: nil, symbol: "clock")
                if recentTags.isEmpty {
                    Text("输入关键词，站源、TMDB、Bangumi 会同时搜索。")
                        .font(.system(size: 11))
                        .foregroundStyle(PXTheme.textTertiary)
                } else {
                    FlowLayout(spacing: 7) {
                        ForEach(recentTags, id: \.self) { term in
                            Button {
                                model.query = term
                                model.submit()
                            } label: {
                                PXChip(title: term)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                Spacer()
            }
            .padding(20)
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(model.results) { result in
                        resultRow(result)
                    }
                }
                .padding(.horizontal, PXTheme.contentPadding)
                .padding(.bottom, 24)
            }
        }
    }

    @ViewBuilder
    private func resultRow(_ result: PXSearchResult) -> some View {
        switch result.source {
        case .catalog:
            if let entry = result.catalogEntry {
                NavigationLink {
                    PXDetailView(entry: entry)
                } label: {
                    card(result)
                }
                .buttonStyle(.plain)
            }
        case .bangumi:
            if let subject = result.bangumiResult {
                NavigationLink {
                    PXBangumiDetailView(subjectID: subject.id, initial: subject)
                } label: {
                    card(result)
                }
                .buttonStyle(.plain)
            }
        case .tmdb:
            if let tmdb = result.tmdbResult {
                Button {
                    preview = PXMediaRecommendation(
                        tmdbID: tmdb.id,
                        mediaType: tmdb.mediaKind(fallback: .series),
                        title: tmdb.displayTitle,
                        overview: tmdb.overview,
                        posterPath: tmdb.posterPath,
                        backdropPath: tmdb.backdropPath,
                        year: tmdb.year,
                        rating: tmdb.voteAverage
                    )
                } label: {
                    card(result)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func card(_ result: PXSearchResult) -> some View {
        HStack(spacing: 11) {
            PXRemoteImage(url: result.imageURL, maxPixel: 300)
                .frame(width: 58, height: 87)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 4) {
                Text(result.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(PXTheme.textPrimary)
                    .lineLimit(2)
                HStack(spacing: 5) {
                    if let badge = result.badge { PXTag(text: badge, tint: PXTheme.accent) }
                    if let subtitle = result.subtitle { PXTag(text: subtitle) }
                }
                if let overview = result.overview, !overview.isEmpty {
                    Text(overview).font(.system(size: 10)).foregroundStyle(PXTheme.textTertiary).lineLimit(2)
                }
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 10, weight: .bold)).foregroundStyle(PXTheme.textTertiary)
        }
        .padding(9)
        .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 12))
    }

    private var recentTags: [String] {
        recentRaw.split(separator: "|").map(String.init).filter { !$0.isEmpty }
    }

    private func saveRecent(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var values = recentTags.filter { $0 != trimmed }
        values.insert(trimmed, at: 0)
        recentRaw = values.prefix(8).joined(separator: "|")
    }
}
