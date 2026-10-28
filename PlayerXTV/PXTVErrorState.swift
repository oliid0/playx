import SwiftUI
struct PXTVErrorState: View {
    var title: String
    var message: String
    var retry: (() -> Void)?
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle").font(.system(size: 40)).foregroundStyle(PXTheme.warning)
            Text(title).font(PXFont.title(24)).foregroundStyle(PXTheme.textPrimary)
            Text(message).font(.body).foregroundStyle(PXTheme.textSecondary).multilineTextAlignment(.center)
            if let retry { Button("重试", action: retry).buttonStyle(PXTVPrimaryButtonStyle()) }
        }
        .frame(maxWidth: .infinity).padding(50)
    }
}
