import SwiftUI

struct PXPlayerSettingsSheet: View {
    @ObservedObject var model: PXPlayerModel
    @ObservedObject private var sleepTimer: PXPlaybackSleepTimer
    @ObservedObject private var preferences = PXPlayerPreferences.shared
    @ObservedObject private var appSettings = PXAppSettings.shared
    @Environment(\.dismiss) private var dismiss

    init(model: PXPlayerModel) {
        self.model = model
        self.sleepTimer = model.sleepTimer
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    engineSection
                    playbackSection
                    trackSection
                    danmakuSection
                    if model.engineKind.capabilities.contains(.subtitleStyle) {
                        subtitleSection
                    }
                    resetSection
                }
                .padding(20)
            }
            .background(PXPageBackground())
            .navigationTitle("播放设置")
            .pxInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var engineSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("播放内核", subtitle: "切换后立即重建当前视频，进度保留")
            ForEach(PXPlayerEngineKind.allCases) { kind in
                Button {
                    model.switchEngine(kind)
                } label: {
                    HStack(alignment: .top, spacing: 11) {
                        Image(systemName: kind.symbol)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(kind == model.engineKind ? PXTheme.accent : PXTheme.textSecondary)
                            .frame(width: 26)
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Text(kind.title).font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(PXTheme.textPrimary)
                                if kind == model.engineKind {
                                    PXTag(text: "使用中", tint: PXTheme.accent)
                                }
                                if !kind.isAvailable { PXTag(text: "不可用", tint: PXTheme.textTertiary) }
                            }
                            Text(kind.summary)
                                .font(.system(size: 10))
                                .foregroundStyle(PXTheme.textTertiary)
                            if let reason = kind.unavailableReason {
                                Text(reason).font(.system(size: 9)).foregroundStyle(PXTheme.warning)
                            }
                            FlowLayout(spacing: 4) {
                                ForEach(Array(kind.capabilities).sorted { $0.rawValue < $1.rawValue }, id: \.self) { cap in
                                    Text(cap.title)
                                        .font(.system(size: 8, weight: .medium))
                                        .foregroundStyle(PXTheme.textTertiary)
                                        .padding(.horizontal, 5)
                                        .frame(height: 16)
                                        .background(PXTheme.surfaceMuted, in: Capsule())
                                }
                            }
                        }
                        Spacer()
                        Image(systemName: kind == model.engineKind ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(kind == model.engineKind ? PXTheme.accent : PXTheme.textTertiary)
                    }
                    .padding(11)
                    .background(
                        RoundedRectangle(cornerRadius: 13)
                            .fill(kind == model.engineKind ? PXTheme.accent.opacity(0.08) : PXTheme.surfaceMuted)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 13)
                            .strokeBorder(kind == model.engineKind ? PXTheme.accent.opacity(0.35) : PXTheme.stroke, lineWidth: 0.7)
                    )
                }
                .buttonStyle(.plain)
                .disabled(!kind.isAvailable)
            }
        }
    }

    private var playbackSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("播放", subtitle: nil)
            HStack {
                Text("倍速").font(.system(size: 12)).foregroundStyle(PXTheme.textSecondary)
                Spacer()
                HStack(spacing: 6) {
                    ForEach(model.availableRates, id: \.self) { rate in
                        Button {
                            model.setRate(rate)
                        } label: {
                            PXChip(
                                title: rate == 1 ? "1x" : String(format: "%.2gx", rate),
                                selected: abs(model.snapshot.rate - rate) < 0.01
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            Toggle("自动播放下一集", isOn: $preferences.autoPlayNext).tint(PXTheme.accent)
            Toggle("竖屏使用 Stories 布局", isOn: $preferences.portraitStories).tint(PXTheme.accent)
            Toggle("横向拖动快进", isOn: $preferences.dragSeek).tint(PXTheme.accent)
            HStack {
                Text("自动连播等待").font(.system(size: 12)).foregroundStyle(PXTheme.textSecondary)
                Spacer()
                Stepper("\(preferences.autoPlayNextSeconds) 秒", value: $preferences.autoPlayNextSeconds, in: 3...30)
                    .labelsHidden()
                Text("\(preferences.autoPlayNextSeconds) 秒").font(.system(size: 11, weight: .semibold)).foregroundStyle(PXTheme.textTertiary)
            }
            HStack {
                Text("清晰度").font(.system(size: 12)).foregroundStyle(PXTheme.textSecondary)
                Spacer()
                Menu(model.qualityLabel) {
                    Button("自动") { Task { await model.changeQuality(0) } }
                    ForEach(model.plan.qualities ?? [], id: \.self) { q in
                        Button(PXFormat.quality(q)) { Task { await model.changeQuality(q) } }
                    }
                }
                .font(.system(size: 12, weight: .semibold))
            }
        }
        .font(.system(size: 12))
        .foregroundStyle(PXTheme.textPrimary)
        .pxFlatCard()
    }

    private var trackSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("音轨与字幕", subtitle: nil)
            if model.snapshot.audioTracks.isEmpty {
                Text("当前流没有可选音轨").font(.system(size: 10)).foregroundStyle(PXTheme.textTertiary)
            } else {
                ForEach(model.snapshot.audioTracks) { track in
                    Button {
                        model.selectAudio(track)
                    } label: {
                        trackRow(track.title, selected: track.isSelected, symbol: "waveform")
                    }
                    .buttonStyle(.plain)
                }
            }
            if model.snapshot.subtitleTracks.isEmpty {
                Text("当前流没有可选字幕").font(.system(size: 10)).foregroundStyle(PXTheme.textTertiary)
            } else {
                Button {
                    model.selectSubtitle(nil)
                } label: {
                    trackRow("关闭字幕", selected: model.snapshot.selectedSubtitleID == nil, symbol: "captions.bubble")
                }
                .buttonStyle(.plain)
                ForEach(model.snapshot.subtitleTracks) { track in
                    Button {
                        model.selectSubtitle(track)
                    } label: {
                        trackRow(track.title, selected: track.isSelected, symbol: "captions.bubble")
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .pxFlatCard()
    }

    private var danmakuSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("弹幕", subtitle: model.danmaku.errorMessage)
            Toggle("显示弹幕", isOn: Binding(
                get: { model.isDanmakuEnabled },
                set: { _ in model.toggleDanmaku() }
            ))
            .tint(PXTheme.accent)
            if model.danmaku.isLoading {
                PXLoadingCard()
            } else {
                Text("已加载 \(model.danmakuCount) 条 · 来源 弹弹play")
                    .font(.system(size: 10))
                    .foregroundStyle(PXTheme.textTertiary)
            }
            HStack {
                Text("字号").font(.system(size: 11)).foregroundStyle(PXTheme.textSecondary)
                Slider(value: $preferences.danmakuFontSize, in: 12...24, step: 1)
                Text("\(Int(preferences.danmakuFontSize))").font(PXFont.mono(10)).foregroundStyle(PXTheme.textTertiary)
            }
            HStack {
                Text("不透明度").font(.system(size: 11)).foregroundStyle(PXTheme.textSecondary)
                Slider(value: $preferences.danmakuOpacity, in: 0.3...1)
                Text("\(Int(preferences.danmakuOpacity * 100))%").font(PXFont.mono(10)).foregroundStyle(PXTheme.textTertiary)
            }
            HStack {
                Text("速度").font(.system(size: 11)).foregroundStyle(PXTheme.textSecondary)
                Slider(value: $preferences.danmakuSpeed, in: 4...14, step: 1)
                Text("\(Int(preferences.danmakuSpeed))s").font(PXFont.mono(10)).foregroundStyle(PXTheme.textTertiary)
            }
            HStack {
                Text("轨道").font(.system(size: 11)).foregroundStyle(PXTheme.textSecondary)
                Slider(value: Binding(
                    get: { Double(preferences.danmakuTracks) },
                    set: { preferences.danmakuTracks = Int($0) }
                ), in: 2...8, step: 1)
                Text("\(preferences.danmakuTracks)").font(PXFont.mono(10)).foregroundStyle(PXTheme.textTertiary)
            }
            Button {
                model.danmaku.load(title: model.title, episodeNumber: model.currentIndex + 1, dramaID: model.request.drama.id)
            } label: {
                Label("重新匹配弹幕", systemImage: "arrow.clockwise")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(PXTheme.accent)
            }
            .buttonStyle(.plain)
        }
        .pxFlatCard()
    }

    private var subtitleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("字幕外观", subtitle: "Erika 内核支持 libass 样式覆盖")
            HStack {
                Text("字号缩放").font(.system(size: 11)).foregroundStyle(PXTheme.textSecondary)
                Slider(
                    value: Binding(
                        get: { preferences.subtitleScale },
                        set: { model.setSubtitleScale($0) }
                    ),
                    in: 0.6...1.8
                )
                Text(String(format: "%.1fx", preferences.subtitleScale))
                    .font(PXFont.mono(10))
                    .foregroundStyle(PXTheme.textTertiary)
            }
        }
        .pxFlatCard()
    }

    private var resetSection: some View {
        Button {
            preferences.reset()
            dismiss()
        } label: {
            Text("恢复默认播放设置")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(PXTheme.danger)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    private func sectionTitle(_ title: String, subtitle: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(PXFont.section(15)).foregroundStyle(PXTheme.textPrimary)
            if let subtitle { Text(subtitle).font(.system(size: 9)).foregroundStyle(PXTheme.textTertiary) }
        }
    }

    private func trackRow(_ title: String, selected: Bool, symbol: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 11))
                .foregroundStyle(selected ? PXTheme.accent : PXTheme.textTertiary)
            Text(title).font(.system(size: 11, weight: selected ? .semibold : .regular))
                .foregroundStyle(selected ? PXTheme.textPrimary : PXTheme.textSecondary)
            Spacer()
            if selected { Image(systemName: "checkmark").font(.system(size: 9, weight: .bold)).foregroundStyle(PXTheme.accent) }
        }
        .padding(.vertical, 6)
    }
}
