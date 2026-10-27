import SwiftUI

struct SettingsInlineError: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(PXTheme.warning)
            Text(message)
                .font(.caption)
                .foregroundStyle(PXTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(PXTheme.warning.opacity(0.18), lineWidth: 0.7))
    }
}
