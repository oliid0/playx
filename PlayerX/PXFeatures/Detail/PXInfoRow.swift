import SwiftUI

struct PXInfoRow: View {
    var title: String
    var value: String?

    var body: some View {
        if let value, !value.isEmpty {
            HStack(alignment: .top, spacing: 12) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(PXTheme.textTertiary)
                    .frame(width: 52, alignment: .leading)
                Text(value)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(PXTheme.textSecondary)
                    .textSelection(.enabled)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 7)
            .overlay(alignment: .bottom) {
                Rectangle().fill(PXTheme.stroke.opacity(0.5)).frame(height: 0.5)
            }
        }
    }
}
