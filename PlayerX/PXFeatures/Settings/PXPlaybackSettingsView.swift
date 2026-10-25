import SwiftUI

struct PXPlaybackSettingsView: View {
    @ObservedObject private var preferences = PXPlayerPreferences.shared
    @State private var showAdvanced = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PXSettingsSection(title: "播放内核") {
                    ForEach(PXPlayerEngineKind.allCases) { kind in
                        Button {
                            preferences.selectEngine(kind)
                        } label: {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: kind.symbol)
                                    .foregroundStyle(kind == preferences.engine ? PXTheme.accent : PXTheme.textSecondary)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(kind.title).font(.system(size: 13, weight: .semibold)).foregroundStyle(PXTheme.textPrimary)
                                    Text(kind.summary).font(.system(size: 9)).foregroundStyle(PXTheme.textTertiary)
                                    if !kind.isAvailable {
                                        Text(kind.unavailableReason ?? "不可用").font(.system(size: 9)).foregroundStyle(PXTheme.warning)
                                    }
                                }
                                Spacer()
                                Image(systemName: kind == preferences.engine ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(kind == preferences.engine ? PXTheme.accent : PXTheme.textTertiary)
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                        .disabled(!kind.isAvailable)
                        if kind != PXPlayerEngineKind.allCases.last { Divider().overlay(PXTheme.stroke) }
                    }
                }

                Text("切换内核后，下一次播放生效。部分设置会按内核能力自动隐藏（例如 libass 字幕样式仅 Erika 支持）。")
                    .font(.system(size: 10))
                    .foregroundStyle(PXTheme.textTertiary)

                PXSettingsSection(title: "播放行为") {
                    ToggleRow(title: "竖屏 Stories 布局", subtitle: "左右切换上一集/下一集", isOn: $preferences.portraitStories)
                    Divider().overlay(PXTheme.stroke)
                    ToggleRow(title: "自动连播", subtitle: "播放结束后自动进入下一集", isOn: $preferences.autoPlayNext)
                    Divider().overlay(PXTheme.stroke)
                    ToggleRow(title: "记住进度", subtitle: "下次从上次位置继续", isOn: $preferences.rememberProgress)
                    Divider().overlay(PXTheme.stroke)
                    ToggleRow(title: "拖动快进", subtitle: "横滑预览并跳转", isOn: $preferences.dragSeek)
                    Divider().overlay(PXTheme.stroke)
                    ToggleRow(title: "触感反馈", subtitle: "快进、切集时轻震", isOn: $preferences.haptics)
                    Divider().overlay(PXTheme.stroke)
                    ToggleRow(title: "后台画中画", subtitle: "离开 App 时自动 PiP（Pillarbox）", isOn: $preferences.pipOnBackground)
                }

                PXSettingsSection(title: "默认值") {
                    HStack {
                        Text("倍速").font(.system(size: 13)).foregroundStyle(PXTheme.textPrimary)
                        Spacer()
                        Picker("", selection: $preferences.preferredRate) {
                            ForEach([0.5, 0.75, 1, 1.25, 1.5, 1.75, 2], id: \.self) { rate in
                                Text(rate == 1 ? "1x" : String(format: "%.2gx", rate)).tag(rate)
                            }
                        }
                        .labelsHidden()
                    }
                    .padding(.vertical, 8)
                    Divider().overlay(PXTheme.stroke)
                    HStack {
                        Text("清晰度").font(.system(size: 13)).foregroundStyle(PXTheme.textPrimary)
                        Spacer()
                        Picker("", selection: $preferences.preferredQuality) {
                            Text("自动").tag(0)
                            Text("720P").tag(720)
                            Text("1080P").tag(1080)
                            Text("4K").tag(2160)
                        }
                        .labelsHidden()
                    }
                    .padding(.vertical, 8)
                    Divider().overlay(PXTheme.stroke)
                    HStack {
                        Text("快退").font(.system(size: 13)).foregroundStyle(PXTheme.textPrimary)
                        Spacer()
                        Picker("", selection: $preferences.backwardSkip) {
                            ForEach([5.0, 10, 15, 30], id: \.self) { Text("\(Int($0)) 秒").tag($0) }
                        }
                        .labelsHidden()
                    }
                    .padding(.vertical, 8)
                    Divider().overlay(PXTheme.stroke)
                    HStack {
                        Text("快进").font(.system(size: 13)).foregroundStyle(PXTheme.textPrimary)
                        Spacer()
                        Picker("", selection: $preferences.forwardSkip) {
                            ForEach([5.0, 10, 15, 30], id: \.self) { Text("\(Int($0)) 秒").tag($0) }
                        }
                        .labelsHidden()
                    }
                    .padding(.vertical, 8)
                }

                PXSettingsSection(title: "字幕") {
                    HStack {
                        Text("字幕缩放").font(.system(size: 13)).foregroundStyle(PXTheme.textPrimary)
                        Slider(value: $preferences.subtitleScale, in: 0.6...1.8)
                        Text(String(format: "%.1fx", preferences.subtitleScale))
                            .font(PXFont.mono(10)).foregroundStyle(PXTheme.textTertiary)
                    }
                    .padding(.vertical, 8)
                }

                Button("恢复默认") {
                    preferences.reset()
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(PXTheme.danger)
                .frame(maxWidth: .infinity)
            }
            .padding(20)
        }
        .background(PXPageBackground())
        .navigationTitle("播放")
        .pxInlineNavigationTitle()
    }
}

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
