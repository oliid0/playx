import SwiftUI
struct PXSettingsFootnote: View {
    var text: String
    var body: some View {
        Text(text).font(.system(size: 9)).foregroundStyle(PXTheme.textTertiary).lineSpacing(2)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
