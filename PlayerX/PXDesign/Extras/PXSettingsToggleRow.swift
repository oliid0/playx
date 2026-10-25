import SwiftUI
struct PXSettingsToggleRow: View {
    var symbol: String?
    var title: String
    var subtitle: String?
    @Binding var isOn: Bool
    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 10) {
                if let symbol { Image(systemName: symbol).foregroundStyle(PXTheme.accent).frame(width: 22) }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 13)).foregroundStyle(PXTheme.textPrimary)
                    if let subtitle { Text(subtitle).font(.system(size: 9)).foregroundStyle(PXTheme.textTertiary) }
                }
            }
        }
        .tint(PXTheme.accent)
        .padding(.vertical, 6)
    }
}
