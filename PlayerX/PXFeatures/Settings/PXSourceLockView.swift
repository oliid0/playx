import SwiftUI

struct SourceLockView: View {
    @ObservedObject private var lock = SourceLockStore.shared
    @Environment(\.dismiss) private var dismiss
    @State private var pin = ""
    @State private var confirmPin = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            SettingsGlassPage {
                SettingsGlassSection(lock.hasPassword ? "输入密码" : "设置密码") {
                    SettingsTextRow("密码", text: $pin, prompt: "3-12 位数字", isSecure: true)
                    if !lock.hasPassword {
                        SettingsGlassDivider()
                        SettingsTextRow("确认密码", text: $confirmPin, prompt: "再输入一次", isSecure: true)
                    }
                }
                if let errorMessage {
                    SettingsInlineError(message: errorMessage)
                }
                SettingsGlassSection {
                    SettingsActionRow(lock.hasPassword ? "解锁" : "设置", systemImage: "lock.shield") {
                        submit()
                    }
                }
            }
            .background(PXPageBackground())
            .navigationTitle(lock.hasPassword ? "站源密码" : "设置站源密码")
            .pxInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
            }
        }
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 320)
        #endif
    }

    private func submit() {
        do {
            if lock.hasPassword {
                try lock.verify(pin)
            } else {
                guard pin == confirmPin else {
                    errorMessage = "两次输入不一致"
                    return
                }
                try lock.setPassword(pin)
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
