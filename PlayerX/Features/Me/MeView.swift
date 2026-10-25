import SwiftUI
import Foundation

/// 我的：品牌头 + 使用统计 + 播放偏好 + 站源/数据/关于。
/// 页面从「List 设置项」升级为分组玻璃卡：每个分组有标题和说明，设置项用图标区分。
struct MeView: View {
    @ObservedObject private var lock = SourceLockStore.shared
    @ObservedObject private var history = HistoryStore.shared
    @ObservedObject private var follow = FollowStore.shared
    @ObservedObject private var downloads = DownloadStore.shared
    @ObservedObject private var preferences = PlaybackPreferences.shared

    @State private var showingLockSheet = false
    @State private var showingClearHistoryConfirm = false
    @State private var showingResetConfirm = false
    @State private var showingAbout = false

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    profile
                    stats
                    playbackSection
                    danmakuSection
                    downloadSection
                    sourceSection
                    dataSection
                    aboutSection

                    Text("PlayerX 是开源项目 GuoApp 的 Apple 原生客户端，仅供个人学习与自用。")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(AppTheme.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                }
                .padding(.horizontal, AppTheme.contentPadding)
                .padding(.top, 8)
                .padding(.bottom, 32)
                .frame(maxWidth: 980, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("设置")
        .appLargeNavigationTitle()
        .appTransparentNavigationChrome()
        .sheet(isPresented: $showingLockSheet) { SourceLockView() }
        .sheet(isPresented: $showingAbout) { AboutView() }
        .confirmationDialog("清空全部播放历史？", isPresented: $showingClearHistoryConfirm, titleVisibility: .visible) {
            Button("清空", role: .destructive) { history.clearAll() }
            Button("取消", role: .cancel) {}
        } message: {
            Text("追剧里的自动「在看」记录也会一起清除，手动收藏会保留。")
        }
        .confirmationDialog("恢复默认播放设置？", isPresented: $showingResetConfirm, titleVisibility: .visible) {
            Button("恢复默认", role: .destructive) { preferences.reset() }
            Button("取消", role: .cancel) {}
        } message: {
            Text("倍速、清晰度、跳过间隔、HUD、弹幕样式和下载清晰度都会重置。")
        }
        .task { await downloads.refresh() }
    }

    // MARK: - 头部

    private var profile: some View {
        HStack(spacing: 15) {
            AppMark(size: 64)

            VStack(alignment: .leading, spacing: 4) {
                Text("PlayerX")
                    .font(.appTitle(24))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("播放、弹幕与数据设置")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
                HStack(spacing: 5) {
                    Text("v\(AppInfo.version)")
                    Text("·")
                    Text("Apple 原生")
                }
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundStyle(AppTheme.textTertiary)
            }
            Spacer()
        }
        .padding(16)
        .solidCard()
    }

    private var stats: some View {
        HStack(spacing: 10) {
            statTile(value: "\(follow.entries.count)", title: "追剧", icon: "heart.fill", tint: AppTheme.brand)
            statTile(value: "\(downloads.completedJobs.count)", title: "已下载", icon: "arrow.down.circle.fill", tint: AppTheme.mint)
            statTile(value: "\(history.entries.count)", title: "观看记录", icon: "clock.fill", tint: AppTheme.lilac)
        }
    }

    private func statTile(value: String, title: String, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(tint)
            Text(value)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppTheme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .solidCard()
    }

    // MARK: - 设置分组

    private var playbackSection: some View {
        settingsGroup(title: "播放", subtitle: "AVPlayer · 清晰度 · HUD") {
            toggleRow(
                icon: "play.square.stack",
                tint: AppTheme.brand,
                title: "自动连播下一集",
                subtitle: "当前集结束后自动播放，倒计时 5 秒",
                isOn: $preferences.autoPlayNext
            )
            divider
            toggleRow(
                icon: "clock.arrow.circlepath",
                tint: AppTheme.mint,
                title: "记住播放进度",
                subtitle: "再次打开同一集时从上次位置继续",
                isOn: $preferences.remembersProgress
            )
            divider
            pickerRow(
                icon: "speedometer",
                tint: AppTheme.warning,
                title: "默认倍速",
                subtitle: "新打开的播放使用这个速度",
                selection: $preferences.preferredRate
            ) {
                ForEach(PlaybackPreferences.rates, id: \.self) { rate in
                    Text(PlaybackPreferences.rateTitle(rate)).tag(rate)
                }
            }
            divider
            pickerRow(
                icon: "4k.tv",
                tint: AppTheme.lilac,
                title: "默认清晰度",
                subtitle: "站源没有对应清晰度时自动回退",
                selection: $preferences.preferredQuality
            ) {
                ForEach(PlaybackPreferences.qualityOptions, id: \.self) { quality in
                    Text(PlaybackPreferences.qualityTitle(quality)).tag(quality)
                }
            }
            divider
            pickerRow(
                icon: "gobackward",
                tint: AppTheme.mint,
                title: "后退间隔",
                subtitle: "HUD 与键盘 ← 共用",
                selection: $preferences.backwardSkip
            ) {
                ForEach(PlaybackPreferences.skipOptions, id: \.self) { seconds in
                    Text(PlaybackPreferences.skipTitle(seconds)).tag(seconds)
                }
            }
            divider
            pickerRow(
                icon: "goforward",
                tint: AppTheme.brand,
                title: "前进间隔",
                subtitle: "HUD 与键盘 → 共用",
                selection: $preferences.forwardSkip
            ) {
                ForEach(PlaybackPreferences.skipOptions, id: \.self) { seconds in
                    Text(PlaybackPreferences.skipTitle(seconds)).tag(seconds)
                }
            }
            divider
            pickerRow(
                icon: "rectangle.on.rectangle",
                tint: AppTheme.lilac,
                title: "控制层自动隐藏",
                subtitle: "播放中无操作后隐藏；常显则不隐藏",
                selection: $preferences.hudAutoHide
            ) {
                ForEach(PlaybackPreferences.hudAutoHideOptions, id: \.self) { seconds in
                    Text(PlaybackPreferences.hudAutoHideTitle(seconds)).tag(seconds)
                }
            }
            divider
            toggleRow(
                icon: "pip",
                tint: AppTheme.mint,
                title: "切到后台自动画中画",
                subtitle: "离开 App 时尝试启动系统 PiP",
                isOn: $preferences.autoPiP
            )
            divider
            toggleRow(
                icon: "hand.draw",
                tint: AppTheme.warning,
                title: "横向拖动快进/快退",
                subtitle: "在画面空白处左右拖动 seek",
                isOn: $preferences.dragSeekEnabled
            )
            divider
            toggleRow(
                icon: "iphone.radiowaves.left.and.right",
                tint: AppTheme.brand,
                title: "触觉反馈",
                subtitle: "播放、跳过、seek 时轻触觉",
                isOn: $preferences.hapticsEnabled
            )
        }
    }

    private var danmakuSection: some View {
        settingsGroup(title: "弹幕", subtitle: "红果等支持弹幕的站源") {
            toggleRow(
                icon: "text.bubble",
                tint: AppTheme.lilac,
                title: "默认开启弹幕",
                subtitle: "进入支持弹幕的剧集时自动加载",
                isOn: $preferences.danmakuByDefault
            )
            divider
            pickerRow(
                icon: "textformat.size",
                tint: AppTheme.brand,
                title: "字号",
                subtitle: "弹幕文字大小",
                selection: $preferences.danmakuFontSize
            ) {
                ForEach(PlaybackPreferences.danmakuFontOptions, id: \.self) { size in
                    Text(PlaybackPreferences.danmakuFontTitle(size)).tag(size)
                }
            }
            divider
            sliderRow(
                icon: "circle.lefthalf.filled",
                tint: AppTheme.lilac,
                title: "不透明度",
                subtitle: "越低越不遮挡画面",
                value: $preferences.danmakuOpacity,
                range: 0.35...1,
                step: 0.05
            ) {
                "\(Int(preferences.danmakuOpacity * 100))%"
            }
            divider
            pickerRow(
                icon: "hare",
                tint: AppTheme.mint,
                title: "滚动速度",
                subtitle: "弹幕穿过屏幕的速度",
                selection: $preferences.danmakuSpeed
            ) {
                ForEach(PlaybackPreferences.danmakuSpeedOptions, id: \.self) { speed in
                    Text(PlaybackPreferences.danmakuSpeedTitle(speed)).tag(speed)
                }
            }
            divider
            pickerRow(
                icon: "list.number",
                tint: AppTheme.warning,
                title: "显示行数",
                subtitle: "占用画面上方的行数",
                selection: $preferences.danmakuTracks
            ) {
                ForEach(PlaybackPreferences.danmakuTrackOptions, id: \.self) { tracks in
                    Text(PlaybackPreferences.danmakuTrackTitle(tracks)).tag(tracks)
                }
            }
            divider
            toggleRow(
                icon: "shadow",
                tint: AppTheme.lilac,
                title: "文字描边阴影",
                subtitle: "复杂画面上更清晰",
                isOn: $preferences.danmakuShadow
            )
            HStack {
                Image(systemName: "info.circle")
                Text("弹幕样式在下次进入播放器时生效")
                Spacer()
            }
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(AppTheme.textTertiary)
            .padding(.vertical, 9)
        }
    }

    private var downloadSection: some View {
        settingsGroup(title: "下载", subtitle: "只影响新任务") {
            pickerRow(
                icon: "arrow.down.circle",
                tint: AppTheme.mint,
                title: "下载清晰度",
                subtitle: "加入下载队列时传给 Go 核心",
                selection: $preferences.downloadQuality
            ) {
                ForEach(PlaybackPreferences.qualityOptions, id: \.self) { quality in
                    Text(PlaybackPreferences.qualityTitle(quality)).tag(quality)
                }
            }
            divider
            HStack(spacing: 12) {
                settingIcon("internaldrive", tint: AppTheme.textTertiary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("下载任务与缓存")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("在「下载」页暂停、继续或删除")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(AppTheme.textTertiary)
                }
                Spacer()
                Text("\(downloads.completedJobs.count) 个完成")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(AppTheme.textTertiary)
            }
            .padding(.vertical, 11)
        }
    }

    private var sourceSection: some View {
        settingsGroup(title: "站源", subtitle: lock.isUnlockedThisLaunch ? "隐藏站源已解锁" : "默认展示 4 个站源") {
            Button {
                if lock.isUnlockedThisLaunch {
                    lock.lockAgain()
                } else {
                    showingLockSheet = true
                }
            } label: {
                HStack(spacing: 12) {
                    settingIcon("lock.shield", tint: AppTheme.brand)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(lock.hasPassword ? "站源密码" : "设置站源密码")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(lock.hasPassword
                             ? (lock.isUnlockedThisLaunch ? "已解锁，点击重新锁定" : "已设置，点击解锁")
                             : "解锁 \(SourceRegistry.all.filter { !$0.defaultVisible }.count) 个隐藏站源")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppTheme.textTertiary)
                }
                .padding(.vertical, 11)
            }
            .buttonStyle(.plain)

            if lock.isUnlockedThisLaunch {
                divider
                HStack(spacing: 12) {
                    settingIcon("checkmark.shield", tint: AppTheme.mint)
                    Text("解锁状态仅本次运行有效")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppTheme.textTertiary)
                    Spacer()
                }
                .padding(.vertical, 11)
            }
        }
    }

    private var dataSection: some View {
        settingsGroup(title: "数据与缓存", subtitle: "只存本机，不上传服务器") {
            Button {
                showingClearHistoryConfirm = true
            } label: {
                HStack(spacing: 12) {
                    settingIcon("trash", tint: AppTheme.danger)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("清空播放历史")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppTheme.danger)
                        Text(history.entries.isEmpty ? "暂无记录" : "\(history.entries.count) 条观看记录")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                    Spacer()
                }
                .padding(.vertical, 11)
            }
            .buttonStyle(.plain)
            .disabled(history.entries.isEmpty)
            .opacity(history.entries.isEmpty ? 0.45 : 1)

            divider
            Button {
                CoverLoader.clearMemoryCache()
                Haptics.success()
            } label: {
                HStack(spacing: 12) {
                    settingIcon("photo.on.rectangle.angled", tint: AppTheme.lilac)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("清空封面内存缓存")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("释放 NSCache；下次会重新从本机封面缓存读取")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                    Spacer()
                }
                .padding(.vertical, 11)
            }
            .buttonStyle(.plain)

            divider
            Button {
                URLCache.shared.removeAllCachedResponses()
                Haptics.success()
            } label: {
                HStack(spacing: 12) {
                    settingIcon("network", tint: AppTheme.mint)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("清空网络缓存")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("URLCache；不会删除已下载的剧集")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                    Spacer()
                }
                .padding(.vertical, 11)
            }
            .buttonStyle(.plain)

            divider
            Button {
                showingResetConfirm = true
            } label: {
                HStack(spacing: 12) {
                    settingIcon("arrow.counterclockwise", tint: AppTheme.warning)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("恢复默认播放设置")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppTheme.warning)
                        Text("不删除历史、收藏或已下载文件")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                    Spacer()
                }
                .padding(.vertical, 11)
            }
            .buttonStyle(.plain)
        }
    }

    private var aboutSection: some View {
        settingsGroup(title: "关于", subtitle: nil) {
            Button {
                showingAbout = true
            } label: {
                HStack(spacing: 12) {
                    settingIcon("info.circle", tint: AppTheme.lilac)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("关于 PlayerX")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("版本 \(AppInfo.version) (\(AppInfo.build))")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppTheme.textTertiary)
                }
                .padding(.vertical, 11)
            }
            .buttonStyle(.plain)

            divider

            HStack(spacing: 12) {
                settingIcon("airplayvideo", tint: AppTheme.mint)
                VStack(alignment: .leading, spacing: 2) {
                    Text("播放核心")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("AVPlayer · AVPlayerLayer · PiP · AirPlay")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(AppTheme.textTertiary)
                }
                Spacer()
                Text("原生")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(AppTheme.mint)
                    .padding(.horizontal, 7)
                    .frame(height: 20)
                    .background(AppTheme.mint.opacity(0.12), in: Capsule())
            }
            .padding(.vertical, 11)
        }
    }

    // MARK: - 组件

    private func settingsGroup<Content: View>(
        title: String,
        subtitle: String?,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(title)
                    .font(.appSection(17))
                    .foregroundStyle(AppTheme.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(AppTheme.textTertiary)
                        .lineLimit(1)
                }
                Spacer()
            }
            .padding(.horizontal, 2)

            VStack(spacing: 0) {
                content()
            }
            .padding(.horizontal, 14)
            .solidCard()
        }
    }

    private func toggleRow(
        icon: String,
        tint: Color,
        title: String,
        subtitle: String,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: 12) {
            settingIcon(icon, tint: tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(AppTheme.textTertiary)
                    .lineLimit(2)
            }
            Spacer(minLength: 6)
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(AppTheme.brand)
                .scaleEffect(0.86)
        }
        .padding(.vertical, 11)
    }

    private func pickerRow<Value: Hashable, Content: View>(
        icon: String,
        tint: Color,
        title: String,
        subtitle: String,
        selection: Binding<Value>,
        @ViewBuilder options: () -> Content
    ) -> some View {
        HStack(spacing: 12) {
            settingIcon(icon, tint: tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(AppTheme.textTertiary)
                    .lineLimit(2)
            }
            Spacer(minLength: 8)
            Picker("", selection: selection) {
                options()
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .tint(AppTheme.textSecondary)
        }
        .padding(.vertical, 9)
    }

    private func sliderRow(
        icon: String,
        tint: Color,
        title: String,
        subtitle: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        display: @escaping () -> String
    ) -> some View {
        HStack(spacing: 12) {
            settingIcon(icon, tint: tint)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(subtitle)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                    Spacer()
                    Text(display())
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(tint)
                }
                Slider(value: value, in: range, step: step)
                    .tint(tint)
            }
        }
        .padding(.vertical, 10)
    }

    private func settingIcon(_ name: String, tint: Color) -> some View {
        Image(systemName: name)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(AppTheme.textSecondary)
            .frame(width: 28, height: 28)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var divider: some View {
        Rectangle()
            .fill(AppTheme.stroke)
            .frame(height: 0.6)
            .padding(.leading, 44)
    }

}

// MARK: - 关于

private enum AppInfo {
    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    static var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }
}

private struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        AppMark(size: 84)
                            .padding(.top, 16)
                        Text("PlayerX")
                            .font(.appDisplay(30))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("多站源短剧聚合 · iPhone / iPad / Mac 原生客户端")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppTheme.textSecondary)

                        VStack(spacing: 0) {
                            infoRow("版本", "\(AppInfo.version) (\(AppInfo.build))")
                            divider
                            infoRow("播放核心", "AVPlayer + AVPlayerLayer")
                            divider
                            infoRow("画中画 / AirPlay", "系统原生")
                            divider
                            infoRow("最低系统", "iOS / iPadOS 16 · macOS 13")
                        }
                        .padding(.horizontal, 14)
                        .solidCard()
                        .padding(.horizontal, AppTheme.contentPadding)

                        Text("PlayerX 基于开源项目 GuoApp 的 SwiftUI 重写，站源解析与下载调度由 Go 原生核心完成。内容来自公开站源，仅供个人学习与自用，请勿用于商业用途。")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(AppTheme.textTertiary)
                            .lineSpacing(4)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                            .padding(.top, 4)
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("关于")
            .appInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .appConfirmation) {
                    Button("完成") { dismiss() }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 540, minHeight: 600)
        #endif
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(AppTheme.textPrimary)
        }
        .padding(.vertical, 12)
    }

    private var divider: some View {
        Rectangle().fill(AppTheme.stroke).frame(height: 0.6)
    }
}
