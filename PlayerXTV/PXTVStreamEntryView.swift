import SwiftUI

struct PXTVStreamEntryView: View {
    @EnvironmentObject private var app: PXTVAppState
    @Environment(\.dismiss) private var dismiss
    let title: String
    @State private var url = ""
    @State private var notice: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("播放直链").font(PXFont.display(36)).foregroundStyle(PXTheme.textPrimary)
            Text("tvOS 支持通过 HLS / MP4 直链播放。复制播放地址后，用遥控器粘贴到这里。")
                .font(.body).foregroundStyle(PXTheme.textSecondary).lineSpacing(4)
            TextField("https://…/master.m3u8", text: $url)
                .textFieldStyle(.plain)
                .font(.title3)
                .padding(.horizontal, 18)
                .frame(height: 56)
                .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 12))
            if let notice {
                Text(notice).font(.caption).foregroundStyle(PXTheme.warning)
            }
            HStack(spacing: 14) {
                Button {
                    guard !url.isEmpty else { notice = "请输入播放地址"; return }
                    app.play(urlString: url, title: title)
                    dismiss()
                } label: {
                    Label("播放", systemImage: "play.fill")
                }
                .buttonStyle(PXTVPrimaryButtonStyle())
                Button("播放测试流") {
                    app.playTestStream()
                    dismiss()
                }
                .buttonStyle(.card)
                Button("取消") { dismiss() }
                    .buttonStyle(.card)
            }
            Spacer()
        }
        .padding(56)
        .background(PXPageBackground())
    }
}
