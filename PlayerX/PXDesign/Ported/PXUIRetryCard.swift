import SwiftUI

struct PXUIRetryCard: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark").font(.system(size: 18)).foregroundStyle(PXTheme.warning)
            Text(message).font(PXFont.body(12)).foregroundStyle(PXTheme.textSecondary)
            Spacer()
            Button("重试", action: retry).font(PXFont.caption(11)).buttonStyle(.borderless)
        }
        .padding(14)
        .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(PXTheme.stroke))
    }
}
