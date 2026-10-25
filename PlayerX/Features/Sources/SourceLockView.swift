import SwiftUI

/// 第一次用没设过密码时这个表单是"设置密码"；设过之后变成"输入密码"解锁。
struct SourceLockView: View {
    @ObservedObject private var lock = SourceLockStore.shared
    @Environment(\.dismiss) private var dismiss

    @State private var pin = ""
    @State private var confirmPin = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                if lock.hasPassword {
                    Section("输入密码") {
                        SecureField("3-12 位数字", text: $pin)
                            .appNumericKeyboard()
                    }
                } else {
                    Section("设置密码（3-12 位数字）") {
                        SecureField("密码", text: $pin)
                            .appNumericKeyboard()
                        SecureField("再输入一次", text: $confirmPin)
                            .appNumericKeyboard()
                    }
                }
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(AppTheme.danger)
                        .font(.footnote)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppBackground())
            .navigationTitle(lock.hasPassword ? "站源密码" : "设置站源密码")
            .appInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .appCancellation) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .appConfirmation) {
                    Button(lock.hasPassword ? "解锁" : "设置") { submit() }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 460, minHeight: 380)
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
