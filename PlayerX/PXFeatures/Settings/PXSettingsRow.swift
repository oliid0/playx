import SwiftUI

struct PXSettingsRow: View {
    var symbol: String
    var title: String
    var subtitle: String?
    var value: String?
    var tint: Color = PXTheme.accent
    var showsChevron = true

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(PXTheme.textPrimary)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundStyle(PXTheme.textTertiary)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 8)
            if let value, !value.isEmpty {
                Text(value)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(PXTheme.textTertiary)
                    .lineLimit(1)
            }
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(PXTheme.textTertiary.opacity(0.7))
            }
        }
        .padding(.vertical, 9)
        .contentShape(Rectangle())
    }
}

struct PXSettingsSection<Content: View>: View {
    var title: String?
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let title {
                Text(title.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(PXTheme.textTertiary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 5)
            }
            VStack(spacing: 0) { content() }
                .padding(.horizontal, 16)
                .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 15))
                .overlay(RoundedRectangle(cornerRadius: 15).strokeBorder(PXTheme.stroke, lineWidth: 0.7))
        }
    }
}
