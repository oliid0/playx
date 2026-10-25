import SwiftUI

struct PXEpisodeDrawer: View {
    @ObservedObject var model: PXPlayerModel
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var filtered: [(offset: Int, element: Chapter)] {
        let values = Array(model.chapters.enumerated())
        guard !query.isEmpty else { return values }
        return values.filter { $0.element.title.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    PXSearchField(text: $query, prompt: "搜索集数")
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    ForEach(filtered, id: \.element.id) { index, chapter in
                        Button {
                            model.playEpisode(index)
                            dismiss()
                        } label: {
                            PXEpisodeCard(
                                chapter: chapter,
                                index: index + 1,
                                isCurrent: index == model.currentIndex,
                                isWatched: index < model.currentIndex,
                                progress: index == model.currentIndex ? model.progress : 0
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .background(PXPageBackground())
            .navigationTitle("选集")
            .pxInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
