import SwiftUI

struct PXFollowView: View {
    @ObservedObject private var follow = FollowStore.shared
    @State private var status: FollowStatus? = .watching

    private var entries: [FollowEntry] {
        guard let status else { return follow.entries }
        return follow.entries.filter { $0.status == status }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 7) {
                    chip(nil, title: "全部")
                    chip(.wish, title: "想看")
                    chip(.watching, title: "在看")
                    chip(.watched, title: "已看")
                }
                .padding(.horizontal, PXTheme.contentPadding)
                if entries.isEmpty {
                    PXEmptyState(title: "还没有收藏", message: "在详情页点按心形图标，把内容加入想看。", symbol: "heart.slash")
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: 14)], spacing: 18) {
                        ForEach(entries) { entry in
                            if let descriptor = SourceRegistry.descriptor(for: entry.drama.source) {
                                NavigationLink {
                                    PXDetailView(entry: PXCatalogEntry(drama: entry.drama, section: .library, providerID: descriptor.id))
                                } label: {
                                    VStack(alignment: .leading, spacing: 6) {
                                        PXPosterCard(entry: PXCatalogEntry(drama: entry.drama, section: .library, providerID: descriptor.id), width: 132)
                                        PXTag(text: entry.status.title, tint: PXTheme.accent)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, PXTheme.contentPadding)
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 30)
        }
        .background(PXPageBackground())
        .navigationTitle("我的追剧")
        .pxInlineNavigationTitle()
    }

    private func chip(_ value: FollowStatus?, title: String) -> some View {
        Button {
            status = value
        } label: {
            PXChip(title: title, selected: status == value)
        }
        .buttonStyle(.plain)
    }
}

extension FollowStatus {
    var title: String {
        switch self {
        case .planned: "想看"
        case .watching: "在看"
        case .watched: "已看"
        }
    }
}
