import SwiftUI

struct PXDetailCast: View {
    @ObservedObject var model: PXDetailViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            if !model.cast.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("演员").font(PXFont.section(17)).foregroundStyle(PXTheme.textPrimary)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 84), spacing: 12)], spacing: 16) {
                        ForEach(model.cast) { member in
                            PXCastCard(member: member)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            if !model.crew.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("制作").font(PXFont.section(17)).foregroundStyle(PXTheme.textPrimary)
                    FlowLayout(spacing: 7) {
                        ForEach(model.crew) { member in
                            PXTag(text: "\(member.name) · \(member.roleText)", tint: PXTheme.textSecondary)
                        }
                    }
                }
            }
            if model.cast.isEmpty && model.crew.isEmpty {
                PXEmptyState(
                    title: "暂无演员信息",
                    message: "匹配 TMDB 后会自动补全演员、导演和角色信息。",
                    symbol: "person.2.slash"
                )
            }
        }
        .padding(.horizontal, PXTheme.contentPadding)
    }
}
