import SwiftUI

struct PXTVSearchView: View {
    @EnvironmentObject private var app: PXTVAppState
    @State private var query = ""

    private let columns = [GridItem(.adaptive(minimum: 190), spacing: 24)]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 26) {
                Text("搜索").font(PXFont.display(44)).foregroundStyle(PXTheme.textPrimary)
                HStack(spacing: 12) {
                    TextField("搜索电影 / 剧集 / 动漫", text: $query)
                        .textFieldStyle(.plain)
                        .font(.title3)
                        .padding(.horizontal, 18)
                        .frame(height: 54)
                        .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 12))
                        .onSubmit {
                            app.searchQuery = query
                            Task { await app.search() }
                        }
                    Button {
                        app.searchQuery = query
                        Task { await app.search() }
                    } label: {
                        Label("搜索", systemImage: "magnifyingglass")
                    }
                    .buttonStyle(PXTVPrimaryButtonStyle())
                }
                if app.isSearching {
                    PXTVLoadingView(text: "搜索 TMDB")
                } else if app.searchResults.isEmpty {
                    PXTVEmptyView(title: "搜索影视资料", message: "使用遥控器输入片名，选中结果查看详情。", symbol: "magnifyingglass")
                } else {
                    LazyVGrid(columns: columns, spacing: 30) {
                        ForEach(app.searchResults) { media in
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
    }
}
