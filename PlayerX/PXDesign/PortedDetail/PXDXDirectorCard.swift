import SwiftUI

struct PXDXDirectorCard: View {
    let member: PXCastMember
    var body: some View {
        HStack(spacing: 10) {
            PXUIAvatar(url: member.profileURL, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(member.name).font(PXFont.body(12))
                Text(member.job ?? "导演").font(PXFont.caption(9)).foregroundStyle(PXTheme.textTertiary)
            }
            Spacer()
        }
    }
}
