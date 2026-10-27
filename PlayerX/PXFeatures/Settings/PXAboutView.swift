import SwiftUI

struct PXAboutView: View {
    @State private var showLicenses = false

    var body: some View {
        SettingsGlassPage {
            SettingsGlassSection("PlayerX") {
                HStack(spacing: 14) {
                    PXLogoMark(size: 52)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("PlayerX").font(.title3.weight(.bold))
                        Text("多站源 · 多内核 · 原生 Apple 播放器")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .settingsRow()
                SettingsGlassDivider()
                HStack {
                    Text("版本")
                    Spacer()
                    Text("\(PXBundleInfo.version) (\(PXBundleInfo.build))")
                        .foregroundStyle(.secondary)
                }
                .settingsRow()
                SettingsGlassDivider()
                HStack {
                    Text("设备")
                    Spacer()
                    Text("\(PXDeviceInfo.name) · \(PXDeviceInfo.system)")
                        .foregroundStyle(.secondary)
                }
                .settingsRow()
            }

            SettingsGlassSection("链接") {
                Link(destination: URL(string: "https://github.com/oliid0/playx")!) {
                    SettingsNavRowContent(title: "PlayerX 项目主页", icon: .symbol("chevron.left.forwardslash.chevron.right"))
                }
                SettingsGlassDivider()
                Link(destination: URL(string: "https://github.com/SRGSSR/pillarbox-apple")!) {
                    SettingsNavRowContent(title: "Pillarbox", icon: .symbol("circle.grid.cross"))
                }
                SettingsGlassDivider()
                Link(destination: URL(string: "https://github.com/AimesSoft/Erika")!) {
                    SettingsNavRowContent(title: "Erika", icon: .symbol("bolt"))
                }
            }

            SettingsGlassSection("许可") {
                SettingsActionRow("开源许可", systemImage: "doc.text") { showLicenses = true }
            }

            SettingsGlassSection("说明") {
                SettingsNote("内容来自公开站源与用户添加的媒体源，App 不托管任何视频文件。TMDB、Bangumi、弹弹play、MoviePilot 为第三方服务。")
                SettingsNote("This product uses the TMDB API but is not endorsed or certified by TMDB.")
            }
        }
        .navigationTitle("关于")
        .pxInlineNavigationTitle()
        .sheet(isPresented: $showLicenses) { PXLicenseView() }
    }
}

struct PXLicenseView: View {
    @Environment(\.dismiss) private var dismiss
    private let licenses: [(String, String)] = [
        ("Pillarbox", "MIT · SRG SSR"),
        ("Erika", "MPL-2.0 · FFmpeg/libass LGPL"),
        ("TMDB", "TMDB API Terms"),
        ("Bangumi", "Bangumi API Terms"),
        ("弹弹play", "Dandanplay Open API"),
        ("MoviePilot", "MIT"),
    ]

    var body: some View {
        NavigationStack {
            SettingsGlassPage {
                SettingsGlassSection("第三方组件") {
                    ForEach(Array(licenses.enumerated()), id: \.offset) { index, item in
                        if index > 0 { SettingsGlassDivider() }
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.0)
                                Text(item.1).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .settingsRow()
                    }
                }
            }
            .background(PXPageBackground())
            .navigationTitle("开源许可")
            .pxInlineNavigationTitle()
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { dismiss() } } }
        }
        .preferredColorScheme(.dark)
    }
}
