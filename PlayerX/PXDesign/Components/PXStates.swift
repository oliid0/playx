import SwiftUI

struct PXEmptyState: View {
    var title: String
    var message: String
    var symbol: String = "rectangle.on.rectangle.slash"
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(PXTheme.textTertiary)
            Text(title)
                .font(PXFont.title(18))
                .foregroundStyle(PXTheme.textPrimary)
            Text(message)
                .font(PXFont.caption(13))
                .foregroundStyle(PXTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .frame(maxWidth: 340)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(PXSecondaryButtonStyle(compact: true))
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 52)
        .padding(.horizontal, 20)
    }
}

struct PXErrorBanner: View {
    var message: String
    var retry: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(PXTheme.warning)
            Text(message)
                .font(PXFont.caption(11))
                .foregroundStyle(PXTheme.textSecondary)
                .lineLimit(3)
            Spacer(minLength: 4)
            if let retry {
                Button("重试", action: retry)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(PXTheme.accent)
                    .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(PXTheme.warning.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(PXTheme.warning.opacity(0.16), lineWidth: 0.7))
    }
}

struct PXLoadingCard: View {
    var body: some View {
        HStack(spacing: 10) {
            ProgressView().controlSize(.small).tint(PXTheme.accent)
            Text("正在加载")
                .font(PXFont.caption(11))
                .foregroundStyle(PXTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
    }
}

struct PXToast: View {
    var message: String

    var body: some View {
        Text(message)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(PXTheme.textPrimary)
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(PXTheme.strokeStrong, lineWidth: 0.8))
            .shadow(color: .black.opacity(0.28), radius: 16, y: 6)
    }
}
