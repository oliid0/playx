import SwiftUI
struct PXTVPersonCard: View {
    var member: PXCastMember
    var body: some View {
        VStack(spacing: 8) {
            PXRemoteImage(url: member.profileURL, maxPixel: 400)
                .frame(width: 130, height: 170).clipShape(RoundedRectangle(cornerRadius: 10))
            Text(member.name).font(.system(size: 15, weight: .semibold)).foregroundStyle(PXTheme.textPrimary).lineLimit(1)
            Text(member.roleText).font(.caption2).foregroundStyle(PXTheme.textTertiary).lineLimit(1)
        }
        .frame(width: 130)
    }
}
