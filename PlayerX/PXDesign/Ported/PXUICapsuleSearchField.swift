import SwiftUI

struct PXUICapsuleSearchField: View {
    let placeholder: String
    @Binding var text: String
    var onSubmit: (() -> Void)?

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").font(.system(size: 12, weight: .semibold)).foregroundStyle(PXTheme.textTertiary)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(PXFont.body(13))
                .onSubmit { onSubmit?() }
            if !text.isEmpty {
                Button { text = "" } label: { Image(systemName: "xmark.circle.fill") }
                    .buttonStyle(.plain).foregroundStyle(PXTheme.textTertiary)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 9)
        .background(PXTheme.surface, in: Capsule())
        .overlay(Capsule().strokeBorder(PXTheme.stroke))
    }
}
