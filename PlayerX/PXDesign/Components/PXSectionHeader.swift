import SwiftUI

struct PXSectionHeader: View {
    var title: String
    var subtitle: String?
    var symbol: String?
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 7) {
                    if let symbol {
                        Image(systemName: symbol)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(PXTheme.accent)
                    }
                    Text(title)
                        .font(PXFont.section())
                        .foregroundStyle(PXTheme.textPrimary)
                }
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(PXFont.caption())
                        .foregroundStyle(PXTheme.textTertiary)
                }
            }
            Spacer(minLength: 8)
            if let actionTitle, let action {
                Button(action: action) {
                    HStack(spacing: 3) {
                        Text(actionTitle)
                        Image(systemName: "chevron.right").font(.system(size: 9, weight: .bold))
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(PXTheme.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
