import SwiftUI

struct PXTVSourceLibraryView: View {
    @EnvironmentObject private var app: PXTVAppState
    let sourceID: String
    @State private var categories: [SourceCategory] = []
    @State private var selectedCategory: String = ""
    @State private var items: [Drama] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var descriptor: SourceDescriptor? {
        PXExternalSourceRegistry.descriptors.first { $0.id == sourceID }
    }

    private let columns = [GridItem(.adaptive(minimum: 190), spacing: 24)]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                header
                if !categories.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(categories) { category in
                                Button(category.name) {
                                    selectedCategory = category.id
                                    Task { await load(category: category.id) }
                                }
                                .buttonStyle(.card)
                            }
                        }
                    }
                }
                if isLoading {
                    PXTVLoadingView(text: "加载媒体库")
                } else if let errorMessage {
                    PXTVErrorState(title: "媒体库加载失败", message: errorMessage) {
                        Task { await load(category: selectedCategory) }
                    }
                } else if items.isEmpty {
                    PXTVEmptyView(title: "媒体库为空", message: "这个分类下没有可显示的内容。", symbol: "rectangle.stack")
                } else {
                    LazyVGrid(columns: columns, spacing: 30) {
                        ForEach(items) { drama in
                            NavigationLink(value: PXTVRoute.sourceDetail(sourceID, drama)) {
                                PXTVSourceTile(drama: drama)
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
        .task { await load(category: "") }
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text(descriptor?.displayName ?? "媒体库")
                    .font(PXFont.display(42))
                    .foregroundStyle(PXTheme.textPrimary)
                Text(descriptor?.subtitle ?? descriptor?.kind.title ?? "媒体源")
                    .font(.body)
                    .foregroundStyle(PXTheme.textTertiary)
            }
            Spacer()
            Button("媒体源设置") { app.path.append(.sources) }
                .buttonStyle(.card)
        }
    }

    private func load(category: String) async {
        guard let provider = descriptor?.provider else {
            errorMessage = "媒体源不存在"
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            if categories.isEmpty {
                categories = try await provider.categories()
            }
            let target = category.isEmpty ? (categories.first?.id ?? "") : category
            selectedCategory = target
            let result = try await provider.catalog(category: target, page: 1, query: nil)
            items = result.items
        } catch {
            errorMessage = error.localizedDescription
            items = []
        }
        isLoading = false
    }
}

struct PXTVSourceTile: View {
    let drama: Drama

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            PXRemoteImage(url: URL(string: drama.cover ?? ""), maxPixel: 600)
                .frame(width: 190, height: 285)
                .clipShape(RoundedRectangle(cornerRadius: 11))
            VStack(alignment: .leading, spacing: 3) {
                Text(drama.title).font(.system(size: 18, weight: .semibold)).foregroundStyle(PXTheme.textPrimary).lineLimit(1)
                Text(drama.pxDisplaySubtitle).font(.caption).foregroundStyle(PXTheme.textTertiary).lineLimit(1)
            }
            .frame(width: 190, alignment: .leading)
        }
        .frame(width: 190)
    }
}
