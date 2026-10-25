import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
struct PXCopyButton: View {
    var text: String
    var label: String = "复制"
    @State private var copied = false
    var body: some View {
        Button {
            #if os(iOS)
            UIPasteboard.general.string = text
            #elseif os(macOS)
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
            #endif
            copied = true
            Task { try? await Task.sleep(nanoseconds: 1_200_000_000); copied = false }
        } label: {
            Label(copied ? "已复制" : label, systemImage: copied ? "checkmark" : "doc.on.doc")
                .font(.system(size: 10, weight: .semibold))
        }
        .buttonStyle(.plain)
        .foregroundStyle(copied ? PXTheme.mint : PXTheme.textSecondary)
    }
}
