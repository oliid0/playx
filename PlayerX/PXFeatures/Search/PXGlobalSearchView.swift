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
            if !model.results.isEmpty { resultToolbar }
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
        .task(id: model.query) {
            let text = model.query.trimmingCharacters(in: .whitespacesAndNewlines)
            guard text.count >= 2, text != model.submittedQuery else { return }
            try? await Task.sleep(nanoseconds: 650_000_000)
            guard !Task.isCancelled else { return }
            model.submit()
        }
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
            VStack(spacing: 12) {
                PXLoadingCard()
                Text("正在搜索 \(model.searchedSourceCount) 个站源与媒体源…")
                    .font(.system(size: 10)).foregroundStyle(PXTheme.textTertiary)
            }
            Spacer()
        } else if !model.submittedQuery.isEmpty && model.results.isEmpty {
            VStack(spacing: 10) {
                Image(systemName: "magnifyingglass").font(.system(size: 28, weight: .light)).foregroundStyle(PXTheme.textTertiary)
                Text("没有找到「\(model.submittedQuery)」").font(PXFont.section(17))
                Text("已搜索全部 \(max(model.searchedSourceCount, model.totalSourceCount)) 个站源与外部媒体源；\(model.warnings.first ?? "换个关键词试试")")
                    .font(.system(size: 11)).foregroundStyle(PXTheme.textTertiary).multilineTextAlignment(.center)
                if !model.warnings.isEmpty {
                    PXUIWarningBanner(text: model.warnings.joined(separator: "\n"))
                        .padding(.top, 6)
                }
            }
            .padding(20)
            Spacer()
        } else if model.results.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                PXSectionHeader(title: "最近搜索", subtitle: nil, symbol: "clock")
                if recentTags.isEmpty {
                    Text("输入关键词，全部站源、TMDB、Bangumi 会同时搜索。")
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
                    if !model.warnings.isEmpty {
                        PXUIWarningBanner(text: model.warnings.joined(separator: "\n"))
                            .padding(.bottom, 4)
                    }
                    ForEach(model.displayedResults) { result in
                        resultRow(result)
                    }
                }
                .padding(.horizontal, PXTheme.contentPadding)
                .padding(.bottom, 24)
            }
        }
    }

    private var resultToolbar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text("全部站源").font(PXFont.caption(10)).foregroundStyle(PXTheme.textTertiary)
                Text("\(model.results.count) 条 · \(model.totalSourceCount) 个源")
                    .font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
                Spacer()
                if model.isSearching { ProgressView().controlSize(.mini) }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    PXUIOptionChip(title: "全部 \(model.results.count)", isSelected: model.selectedSourceID == nil) {
                        model.selectedSourceID = nil
                    }
                    ForEach(model.sourceOptions, id: \.id) { option in
                        PXUIOptionChip(title: "\(option.name) \(option.count)", isSelected: model.selectedSourceID == option.id) {
                            model.selectedSourceID = option.id
                        }
                    }
                    ForEach(bangumiSources, id: \.id) { option in
                        PXUIOptionChip(title: "\(option.name) \(option.count)", isSelected: model.selectedSourceID == option.id) {
                            model.selectedSourceID = option.id
                        }
                    }
                }
            }
        }
        .padding(.horizontal, PXTheme.contentPadding)
        .padding(.bottom, 10)
    }

    private var bangumiSources: [PXSearchSourceOption] {
        var values: [PXSearchSourceOption] = []
        let tmdb = model.results.filter { $0.source == .tmdb }.count
        let bgm = model.results.filter { $0.source == .bangumi }.count
        if tmdb > 0 { values.append(PXSearchSourceOption(id: "tmdb", name: "TMDB", count: tmdb)) }
        if bgm > 0 { values.append(PXSearchSourceOption(id: "bangumi", name: "Bangumi", count: bgm)) }
        return values
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
            Group {
                if let entry = result.catalogEntry {
                    PXCoverImage(drama: entry.drama, maxPixel: 300)
                } else {
                    PXRemoteImage(url: result.imageURL, maxPixel: 300)
                }
            }
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
