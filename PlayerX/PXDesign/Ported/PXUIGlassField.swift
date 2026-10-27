import SwiftUI

struct PXUIGlassField: View {
    let title: String
    let prompt: String
    @Binding var text: String
    var secure = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(PXFont.caption(11)).foregroundStyle(PXTheme.textSecondary)
            Group {
                if secure { SecureField(prompt, text: $text) } else { TextField(prompt, text: $text) }
            }
            .textFieldStyle(.plain)
            .font(PXFont.body(13))
            .padding(.horizontal, 12).padding(.vertical, 10)
            .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(PXTheme.stroke))
        }
    }
}
