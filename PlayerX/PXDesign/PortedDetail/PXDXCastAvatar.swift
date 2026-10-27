import SwiftUI

struct PXDXCastAvatar: View {
    let member: PXCastMember
    var body: some View {
        VStack(spacing: 5) {
            PXUIAvatar(url: member.profileURL, size: 52)
            Text(member.name).font(PXFont.caption(9)).lineLimit(1).frame(width: 64)
        }
    }
}
