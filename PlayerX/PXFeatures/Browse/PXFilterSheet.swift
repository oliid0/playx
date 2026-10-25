import SwiftUI

struct PXFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: PXCatalogFilter
    let onApply: (PXCatalogFilter) -> Void

    private let genres: [String]
    private let sources: [SourceDescriptor]

    init(section: PXCatalogSection, filter: PXCatalogFilter, onApply: @escaping (PXCatalogFilter) -> Void) {
        _draft = State(initialValue: filter)
        self.onApply = onApply
        self.genres = PXCatalogService.shared.genres(for: section)
        self.sources = PXCatalogService.shared.visibleSources
    }

    init(filter: PXCatalogFilter, onApply: @escaping (PXCatalogFilter) -> Void) {
        _draft = State(initialValue: filter)
        self.onApply = onApply
        self.genres = PXCatalogService.shared.genres(for: .library)
        self.sources = PXCatalogService.shared.visibleSources
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    if let kind = draft.kind {
                        group("类型") {
                            PXTag(text: kind.title, tint: PXTheme.accent)
                        }
                    }
                    if !genres.isEmpty {
                        group("题材") {
                            ForEach(genres, id: \.self) { genre in
                                Button {
                                    draft.genre = draft.genre == genre ? nil : genre
                                } label: {
                                    PXChip(title: genre, selected: draft.genre == genre)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    group("站源") {
                        Button {
                            draft.sourceID = nil
                        } label: {
                            PXChip(title: "全部站源", selected: draft.sourceID == nil)
                        }
                        .buttonStyle(.plain)
                        ForEach(sources) { source in
                            Button {
                                draft.sourceID = draft.sourceID == source.id ? nil : source.id
                            } label: {
                                PXChip(title: source.displayName, selected: draft.sourceID == source.id)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    group("年份") {
                        ForEach(PXCatalogService.shared.years().prefix(10), id: \.self) { year in
                            Button {
                                draft.year = draft.year == year ? nil : year
                            } label: {
                                PXChip(title: String(year), selected: draft.year == year)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    group("排序") {
                        ForEach(PXCatalogSort.allCases) { sort in
                            Button {
                                draft.sort = sort
                            } label: {
                                PXChip(title: sort.title, selected: draft.sort == sort, symbol: sort.symbol)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(20)
            }
            .background(PXPageBackground())
            .navigationTitle("筛选")
            .pxInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("重置") { draft = PXCatalogFilter(kind: draft.kind) }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("应用") {
                        onApply(draft)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func group<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(PXFont.section(15))
                .foregroundStyle(PXTheme.textPrimary)
            FlowLayout(spacing: 7) { content() }
        }
    }

}
