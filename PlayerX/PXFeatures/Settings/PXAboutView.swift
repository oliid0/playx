import SwiftUI

struct PXAboutView: View {
    @State private var showLicenses = false
    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
    private var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                VStack(spacing: 10) {
                    PXLogoMark(size: 74)
                    Text("PlayerX").font(PXFont.display(30)).foregroundStyle(PXTheme.textPrimary)
                    Text("Version \(version) (\(build))")
                        .font(PXFont.mono(10))
                        .foregroundStyle(PXTheme.textTertiary)
                    Text("多站源 · 多内核 · 原生 Apple 播放器")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(PXTheme.textSecondary)
                }
                .padding(.top, 12)
                PXSettingsSection(title: "开源与致谢") {
                    Link(destination: URL(string: "https://github.com/oliid0/playx")!) {
                        PXSettingsRow(symbol: "chevron.left.forwardslash.chevron.right", title: "PlayerX 项目主页")
                    }
                    Divider().overlay(PXTheme.stroke)
                    Link(destination: URL(string: "https://github.com/SRGSSR/pillarbox-apple")!) {
                        PXSettingsRow(symbol: "circle.grid.cross", title: "Pillarbox", subtitle: "默认播放内核")
                    }
                    Divider().overlay(PXTheme.stroke)
                    Link(destination: URL(string: "https://github.com/AimesSoft/Erika")!) {
                        PXSettingsRow(symbol: "bolt", title: "Erika", subtitle: "FFmpeg + libass 内核")
                    }
                    Divider().overlay(PXTheme.stroke)
                    Button { showLicenses = true } label: {
                        PXSettingsRow(symbol: "doc.text", title: "开源许可")
                    }
                    .buttonStyle(.plain)
                }
                Text("内容来自公开站源，App 不托管任何视频文件。TMDB、Bangumi、弹弹play、MoviePilot 为第三方服务。")
                    .font(.system(size: 10))
                    .foregroundStyle(PXTheme.textTertiary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 30)
            }
            .padding(20)
        }
        .background(PXPageBackground())
        .navigationTitle("关于")
        .pxInlineNavigationTitle()
        .sheet(isPresented: $showLicenses) {
            PXLicenseView()
        }
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
            List(licenses, id: \.0) { item in
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.0).font(.system(size: 13, weight: .semibold))
                    Text(item.1).font(.system(size: 10)).foregroundStyle(.secondary)
                }
                .listRowBackground(PXTheme.surfaceMuted)
            }
            .scrollContentBackground(.hidden)
            .background(PXPageBackground())
            .navigationTitle("开源许可")
            .pxInlineNavigationTitle()
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { dismiss() } } }
        }
        .preferredColorScheme(.dark)
    }
}
