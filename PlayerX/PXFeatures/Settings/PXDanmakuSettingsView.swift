import SwiftUI
import PlayXUI

struct PXDanmakuSettingsView: View {
    @ObservedObject private var preferences = PXPlayerPreferences.shared
    @ObservedObject private var settings = PXAppSettings.shared
    @State private var testResult: String?
    @State private var isTesting = false
    @StateObject private var danmaku = PXDanmakuCoordinator()

    var body: some View {
        SettingsGlassPage {
            SettingsGlassSection("弹幕来源") {
                SettingsTextRow("网关", text: $settings.danmakuGateway, prompt: PXAppSettings.builtInDanmakuGateway)
                SettingsGlassDivider()
                SettingsTextRow("API Key", text: $settings.danmakuAPIKey, prompt: "内置公共 Key", isSecure: true)
                SettingsGlassDivider()
                Toggle("自动匹配弹弹play", isOn: $settings.danmakuAutoMatch)
                SettingsNote("按标题与集数匹配；匹配不到不会阻塞播放。")
                SettingsGlassDivider()
                SettingsActionRow(isTesting ? "正在测试…" : "测试网关", systemImage: "bolt.horizontal") {
                    Task { await test() }
                }
                .disabled(isTesting)
                if let testResult {
                    SettingsNote(testResult)
                }
            }

            SettingsGlassSection("默认样式") {
                Toggle("默认显示弹幕", isOn: $preferences.danmakuEnabled)
                SettingsGlassDivider()
                sliderRow("字号", value: $preferences.danmakuFontSize, range: 12...24, format: "%.0f")
                SettingsGlassDivider()
                sliderRow("不透明度", value: $preferences.danmakuOpacity, range: 0.3...1, format: "%.0f%%", multiplier: 100)
                SettingsGlassDivider()
                sliderRow("滚动时长", value: $preferences.danmakuSpeed, range: 4...14, format: "%.0fs")
                SettingsGlassDivider()
                sliderRow("轨道数", value: Binding(
                    get: { Double(preferences.danmakuTracks) },
                    set: { preferences.danmakuTracks = Int($0) }
                ), range: 2...8, format: "%.0f")
                SettingsGlassDivider()
                Toggle("描边阴影", isOn: $preferences.danmakuShadow)
            }

            SettingsGlassSection("弹幕引擎") {
                SettingsNote("内置弹弹play 网关；弹幕由播放器覆盖层绘制，三个内核共用同一套轨道与样式。")
                SettingsActionRow("清除当前弹幕缓存", systemImage: "trash") {
                    danmaku.clear()
                }
            }
        }
        .navigationTitle("弹幕")
        .pxInlineNavigationTitle()
    }

    private func sliderRow(
        _ title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        format: String,
        multiplier: Double = 1
    ) -> some View {
        HStack {
            Text(title)
            Slider(value: value, in: range)
            Text(String(format: format, value.wrappedValue * multiplier))
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 38, alignment: .trailing)
        }
    }

    private func test() async {
        isTesting = true
        testResult = "正在连接…"
        do {
            let episode = try await PXDanmakuClient().episodes(
                title: "进击的巨人",
                episodeNumber: 1,
                gateway: settings.effectiveDanmakuGateway ?? URL(string: PXAppSettings.builtInDanmakuGateway)!,
                apiKey: settings.effectiveDanmakuKey
            )
            testResult = episode == nil ? "连接成功，但未匹配到测试条目" : "连接成功 · \(episode!.animeTitle ?? "")"
        } catch {
            testResult = "连接失败：\(error.localizedDescription)"
        }
        isTesting = false
    }
}
