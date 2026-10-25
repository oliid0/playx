import SwiftUI

struct PXDanmakuSettingsView: View {
    @ObservedObject private var preferences = PXPlayerPreferences.shared
    @ObservedObject private var settings = PXAppSettings.shared
    @State private var testResult: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PXSettingsSection(title: "弹幕来源") {
                    TextField("网关地址", text: $settings.danmakuGateway)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .padding(.vertical, 10)
                    Divider().overlay(PXTheme.stroke)
                    SecureField("API Key", text: $settings.danmakuAPIKey)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .padding(.vertical, 10)
                    Divider().overlay(PXTheme.stroke)
                    ToggleRow(title: "自动匹配", subtitle: "按标题与集数匹配弹弹play 弹幕", isOn: $settings.danmakuAutoMatch)
                }
                Text("默认使用内置公共网关，开箱即用。也可以填自建网关与自己的 API Key。")
                    .font(.system(size: 10)).foregroundStyle(PXTheme.textTertiary)
                Button {
                    Task {
                        testResult = "正在连接…"
                        do {
                            let episodes = try await PXDanmakuClient().episodes(
                                title: "进击的巨人",
                                episodeNumber: 1,
                                gateway: settings.effectiveDanmakuGateway ?? URL(string: "https://dandanplay.3841625.xyz")!,
                                apiKey: settings.effectiveDanmakuKey
                            )
                            testResult = episodes == nil ? "连接成功，但未匹配到测试条目" : "连接成功 · \(episodes!.animeTitle ?? "")"
                        } catch {
                            testResult = "连接失败：\(error.localizedDescription)"
                        }
                    }
                } label: {
                    Label("测试网关", systemImage: "bolt.horizontal")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PXSecondaryButtonStyle())
                if let testResult { Text(testResult).font(.system(size: 10)).foregroundStyle(PXTheme.textSecondary) }

                PXSettingsSection(title: "默认样式") {
                    ToggleRow(title: "默认显示弹幕", subtitle: nil, isOn: $preferences.danmakuEnabled)
                    Divider().overlay(PXTheme.stroke)
                    sliderRow("字号", value: $preferences.danmakuFontSize, range: 12...24, format: "%.0f")
                    Divider().overlay(PXTheme.stroke)
                    sliderRow("不透明度", value: $preferences.danmakuOpacity, range: 0.3...1, format: "%.2f")
                    Divider().overlay(PXTheme.stroke)
                    sliderRow("滚动时长", value: $preferences.danmakuSpeed, range: 4...14, format: "%.0fs")
                    Divider().overlay(PXTheme.stroke)
                    sliderRow("轨道数", value: Binding(
                        get: { Double(preferences.danmakuTracks) },
                        set: { preferences.danmakuTracks = Int($0) }
                    ), range: 2...8, format: "%.0f")
                    Divider().overlay(PXTheme.stroke)
                    ToggleRow(title: "描边阴影", subtitle: nil, isOn: $preferences.danmakuShadow)
                }
            }
            .padding(20)
        }
        .background(PXPageBackground())
        .navigationTitle("弹幕")
        .pxInlineNavigationTitle()
    }

    private func sliderRow(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, format: String) -> some View {
        HStack {
            Text(title).font(.system(size: 13)).foregroundStyle(PXTheme.textPrimary)
            Slider(value: value, in: range)
            Text(String(format: format, value.wrappedValue))
                .font(PXFont.mono(10))
                .foregroundStyle(PXTheme.textTertiary)
                .frame(width: 36, alignment: .trailing)
        }
        .padding(.vertical, 8)
    }
}
