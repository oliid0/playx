import SwiftUI
import PlayXUI

struct PXPlaybackSettingsView: View {
    @ObservedObject private var preferences = PXPlayerPreferences.shared

    var body: some View {
        SettingsGlassPage {
            SettingsGlassSection("播放内核") {
                SettingsPickerRow("内核", selection: Binding(
                    get: { preferences.engine },
                    set: { preferences.selectEngine($0) }
                )) {
                    ForEach(PXPlayerEngineKind.allCases) { kind in
                        Text(kind.isAvailable ? kind.title : "\(kind.title)（不可用）")
                            .tag(kind)
                    }
                }
                SettingsNote(preferences.engine.summary)
                SettingsNote(capabilitiesText)
            }

            SettingsGlassSection("播放行为") {
                Toggle("竖屏 Stories 布局", isOn: $preferences.portraitStories)
                SettingsNote("竖屏视频使用 Stories 布局：顶部章节进度，左右点击切换上一集/下一集。")
                SettingsGlassDivider()
                Toggle("自动连播", isOn: $preferences.autoPlayNext)
                SettingsGlassDivider()
                Toggle("记住进度", isOn: $preferences.rememberProgress)
                SettingsGlassDivider()
                Toggle("拖动快进", isOn: $preferences.dragSeek)
                SettingsGlassDivider()
                Toggle("触感反馈", isOn: $preferences.haptics)
                SettingsGlassDivider()
                Toggle("后台画中画", isOn: $preferences.pipOnBackground)
            }

            SettingsGlassSection("默认值") {
                SettingsPickerRow("倍速", selection: Binding(
                    get: { preferences.normalizedRate },
                    set: { preferences.preferredRate = $0 }
                )) {
                    ForEach([0.5, 0.75, 1, 1.25, 1.5, 1.75, 2], id: \.self) { rate in
                        Text(rate == 1 ? "正常" : String(format: "%.2gx", rate)).tag(rate)
                    }
                }
                SettingsGlassDivider()
                SettingsPickerRow("清晰度", selection: $preferences.preferredQuality) {
                    Text("自动").tag(0)
                    Text("720P").tag(720)
                    Text("1080P").tag(1080)
                    Text("4K").tag(2160)
                }
                SettingsGlassDivider()
                SettingsPickerRow("快退", selection: $preferences.backwardSkip) {
                    ForEach([5.0, 10, 15, 30], id: \.self) { Text("\(Int($0)) 秒").tag($0) }
                }
                SettingsGlassDivider()
                SettingsPickerRow("快进", selection: $preferences.forwardSkip) {
                    ForEach([5.0, 10, 15, 30], id: \.self) { Text("\(Int($0)) 秒").tag($0) }
                }
                SettingsGlassDivider()
                SettingsPickerRow("自动连播等待", selection: Binding(
                    get: { preferences.autoPlayNextSeconds },
                    set: { preferences.autoPlayNextSeconds = $0 }
                )) {
                    ForEach([3, 5, 8, 10, 15, 20], id: \.self) { Text("\($0) 秒").tag($0) }
                }
            }

            SettingsGlassSection("字幕") {
                HStack {
                    Text("字幕缩放")
                    Slider(value: $preferences.subtitleScale, in: 0.6...1.8)
                    Text(String(format: "%.1fx", preferences.subtitleScale))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                SettingsNote("仅 Erika 内核支持 libass 字幕样式覆盖；Pillarbox / 原生内核使用系统字幕。")
            }

            SettingsGlassSection("重置") {
                SettingsActionRow("恢复默认播放设置", systemImage: "arrow.counterclockwise", role: .destructive) {
                    preferences.reset()
                }
            }
        }
        .navigationTitle("播放")
        .pxInlineNavigationTitle()
    }

    private var capabilitiesText: String {
        preferences.engine.capabilities
            .sorted { $0.rawValue < $1.rawValue }
            .map(\.title)
            .joined(separator: " · ")
    }
}

/// 兼容旧页面的开关行；新设置页一律直接用 `Toggle` + Glass 承载。
struct ToggleRow: View {
    var title: String
    var subtitle: String?
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 13)).foregroundStyle(PXTheme.textPrimary)
                if let subtitle { Text(subtitle).font(.system(size: 9)).foregroundStyle(PXTheme.textTertiary) }
            }
        }
        .tint(PXTheme.accent)
        .padding(.vertical, 8)
    }
}
