import SwiftUI

struct PXUIChevronRow<Content: View>: View {
    var action: (() -> Void)?
    let content: Content

    init(action: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.action = action
        self.content = content()
    }

    var body: some View {
        Button { action?() } label: {
            HStack(spacing: 10) {
                content
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(PXTheme.textTertiary)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
