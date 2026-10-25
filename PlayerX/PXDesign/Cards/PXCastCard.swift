import SwiftUI

struct PXCastCard: View {
    var member: PXCastMember
    var width: CGFloat = 92

    var body: some View {
        VStack(spacing: 7) {
            PXRemoteImage(url: member.profileURL, maxPixel: width * 3)
                .frame(width: width, height: width * 1.16)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .strokeBorder(PXTheme.stroke, lineWidth: 0.6)
                }
            VStack(spacing: 2) {
                Text(member.name)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(PXTheme.textPrimary)
                    .lineLimit(1)
                Text(member.roleText)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(PXTheme.textTertiary)
                    .lineLimit(1)
            }
            .frame(width: width)
        }
        .frame(width: width)
    }
}
