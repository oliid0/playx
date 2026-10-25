import SwiftUI
import AVFoundation

/// 播放器里的选集面板。和详情页的选集不同，这里强调「快速跳集」：
/// 大格子、当前集高亮、已缓存标记，打开时自动滚到当前集。
struct PlayerEpisodeSheet: View {
    @ObservedObject var model: PlayerModel
    @ObservedObject private var downloads = DownloadStore.shared
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.adaptive(minimum: 62), spacing: 8, alignment: .top)
    ]

    var body: some View {
        ZStack {
            AppBackground()

            ScrollViewReader { proxy in
                VStack(spacing: 0) {
                    header
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(Array(model.chapters.enumerated()), id: \.element.id) { index, chapter in
                                episodeButton(index: index, chapter: chapter)
                                    .id(index)
                            }
                        }
                        .padding(.horizontal, AppTheme.contentPadding)
                        .padding(.bottom, 24)
                    }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        withAnimation {
                            proxy.scrollTo(model.currentIndex, anchor: .center)
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("选集")
                    .font(.appSection(19))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("\(model.title) · 共 \(model.chapters.count) 集")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(AppTheme.textTertiary)
                    .lineLimit(1)
            }
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(AppTheme.surface, in: Circle())
            }
            .buttonStyle(AppPressStyle())
            .accessibilityLabel("关闭选集")
        }
        .padding(.horizontal, AppTheme.contentPadding)
        .padding(.top, 18)
        .padding(.bottom, 14)
    }

    private func episodeButton(index: Int, chapter: Chapter) -> some View {
        let current = index == model.currentIndex
        let downloaded = downloads.job(dramaId: model.drama.id, index: index + 1)?.state == DownloadJob.stateCompleted
        return Button {
            guard index != model.currentIndex else {
                dismiss()
                return
            }
            dismiss()
            Task { await model.loadEpisode(index: index, autoPlay: true) }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(current ? AppTheme.brand.opacity(0.20) : AppTheme.surfaceMuted)
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(current ? AppTheme.brand.opacity(0.85) : AppTheme.stroke,
                                  lineWidth: current ? 1.2 : 0.7)
                VStack(spacing: 2) {
                    Text(title(for: chapter, index: index))
                        .font(.system(size: 12, weight: current ? .bold : .semibold, design: .rounded))
                        .foregroundStyle(current ? AppTheme.brandSoft : AppTheme.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    if downloaded {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(AppTheme.mint)
                    }
                }
                .padding(.horizontal, 4)
            }
            .frame(height: 48)
        }
        .buttonStyle(AppPressStyle(scale: 0.95))
        .accessibilityLabel("\(title(for: chapter, index: index))\(downloaded ? "，已缓存" : "")")
        .accessibilityAddTraits(current ? .isSelected : [])
    }

    private func title(for chapter: Chapter, index: Int) -> String {
        if let value = chapter.currentEpisode, !value.isEmpty {
            if value.allSatisfy(\.isNumber) { return "第\(value)集" }
            return value
        }
        return "第\(index + 1)集"
    }
}

/// 播放信息面板：把 Go 解析出来的 route/quality/session 和 AVPlayer 的实时状态摊开，
/// 真机排查「能打开目录但播不了」时不用连 Xcode 看日志。
struct PlayerInfoSheet: View {
    @ObservedObject var model: PlayerModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    infoCard
                    nativeCard
                }
                .padding(.horizontal, AppTheme.contentPadding)
                .padding(.top, 18)
                .padding(.bottom, 26)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("播放信息")
                    .font(.appSection(19))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(model.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.textTertiary)
                    .lineLimit(1)
            }
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(AppTheme.surface, in: Circle())
            }
            .buttonStyle(AppPressStyle())
            .accessibilityLabel("关闭播放信息")
        }
    }

    private var infoCard: some View {
        VStack(spacing: 0) {
            infoRow("站源", model.sourceName)
            divider
            infoRow("当前集数", model.episodeLabel)
            divider
            infoRow("清晰度", model.qualityLabel)
            if model.hasSubtitleOptions {
                divider
                infoRow("字幕", model.selectedSubtitleName)
            }
            if model.hasAudioOptions {
                divider
                infoRow("音轨", model.selectedAudioName)
            }
            divider
            infoRow("播放速度", rateLabel(model.rate))
            if let sleepTimerMinutes = model.sleepTimerMinutes {
                divider
                infoRow("定时关闭", "\(sleepTimerMinutes) 分钟")
            }
            divider
            infoRow("线路", routeLabel)
            divider
            infoRow("地址", hostLabel)
            divider
            infoRow("会话", sessionLabel)
        }
        .padding(.horizontal, 14)
        .solidCard()
    }

    private var nativeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.mint)
                Text("Apple 原生播放链路")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
            }
            Text("AVPlayer 负责解码，AVPlayerLayer 负责画面；画中画和 AirPlay 分别由 AVPictureInPictureController / AVRoutePickerView 提供，字幕/音轨由 AVMediaSelectionGroup 选择、AVPlayerLayer 原生渲染，iOS 后台播放由 AVAudioSession 维持。")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppTheme.textTertiary)
                .lineSpacing(4)
        }
        .padding(14)
        .solidCard()
    }

    private var routeLabel: String {
        guard let plan = model.plan else { return "—" }
        if let index = plan.routeIndex, let count = plan.routeCount {
            return "\(index + 1) / \(count)"
        }
        return plan.local == true ? "本地文件" : "本机代理"
    }

    private var hostLabel: String {
        guard let raw = model.plan?.url, let url = URL(string: raw), let host = url.host else { return "—" }
        return host
    }

    private var sessionLabel: String {
        guard let session = model.plan?.session, !session.isEmpty else { return "—" }
        if session.count <= 10 { return session }
        return "\(session.prefix(6))…\(session.suffix(4))"
    }

    private func rateLabel(_ value: Double) -> String {
        if value == floor(value) { return "\(Int(value))x" }
        return "\(value)x"
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppTheme.textTertiary)
                .frame(width: 58, alignment: .leading)
            Text(value)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 11)
    }

    private var divider: some View {
        Rectangle().fill(AppTheme.stroke).frame(height: 0.6)
    }
}
