import SwiftUI

public struct SettingsInlineError: View {
    let message: String

    public var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(PlayXTheme.warning)
            Text(message)
                .font(.caption)
                .foregroundStyle(PlayXTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(PlayXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(PlayXTheme.warning.opacity(0.18), lineWidth: 0.7))
    }
}
