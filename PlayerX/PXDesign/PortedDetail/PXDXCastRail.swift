import SwiftUI

struct PXDXCastRail: View {
    let cast: [PXCastMember]
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: 12) {
                ForEach(cast) { member in
                    VStack(spacing: 6) {
                        PXUIAvatar(url: member.profileURL, size: 58)
                        Text(member.name).font(PXFont.caption(10)).lineLimit(1).frame(width: 72)
                        Text(member.roleText).font(PXFont.caption(8)).foregroundStyle(PXTheme.textTertiary).lineLimit(1).frame(width: 72)
                    }
                }
            }
        }
    }
}
