import SwiftUI

struct PXTVBrowseView: View {
    @EnvironmentObject private var app: PXTVAppState
    let tab: PXTVTab

    private let columns = [GridItem(.adaptive(minimum: 190), spacing: 24)]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 26) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tab.title).font(PXFont.display(44)).foregroundStyle(PXTheme.textPrimary)
                    Text("\(app.browseItems.count) 部 · TMDB 高分与热门")
                        .font(.body).foregroundStyle(PXTheme.textTertiary)
                }
                if app.browseLoading {
                    PXTVLoadingView(text: "正在加载")
                } else if app.browseItems.isEmpty {
                    PXTVEmptyView(title: "没有内容", message: "TMDB 暂时不可用。", symbol: "film.slash")
                } else {
                    LazyVGrid(columns: columns, spacing: 30) {
                        ForEach(app.browseItems) { media in
                            NavigationLink(value: PXTVRoute.media(media)) {
                                PXTVPosterTile(media: media)
                            }
                            .buttonStyle(.card)
                        }
                    }
                }
            }
            .padding(.horizontal, 56)
            .padding(.top, 46)
            .padding(.bottom, 60)
        }
        .task { await app.loadBrowse(tab) }
    }
}
