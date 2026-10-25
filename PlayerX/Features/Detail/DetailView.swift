import SwiftUI

/// 详情页：模糊封面氛围背景 + 海报/元信息 + 主操作 + 可展开简介 + 选集/多选下载。
/// 版式参考 OcPlayer 的详情页（海报在左、标题/操作在右、下方横向内容区），但适配了
/// 短剧「几十集竖屏」的实际情况：选集用密集网格，下载状态直接叠在集数按钮上。
struct DetailView: View {
    @StateObject private var model: DetailModel
    @ObservedObject private var follow = FollowStore.shared
    @ObservedObject private var history = HistoryStore.shared
    @ObservedObject private var downloads = DownloadStore.shared

    @State private var descriptionExpanded = false
    @State private var isSelectingDownloads = false
    @State private var episodeAscending = true

    private let episodeColumns = [
        GridItem(.adaptive(minimum: 56), spacing: 8, alignment: .top)
    ]

    init(provider: ContentProvider, drama: Drama) {
        _model = StateObject(wrappedValue: DetailModel(provider: provider, drama: drama))
    }

    var body: some View {
        ZStack(alignment: .top) {
            AmbientCoverBackground(drama: model.drama)

            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 22) {
                    header
                    if let warning = model.warning, !warning.isEmpty {
                        notice(text: warning, icon: "info.circle.fill", tint: AppTheme.warning)
                    }
                    if let error = model.errorMessage, !model.chapters.isEmpty {
                        notice(text: error, icon: "exclamationmark.triangle.fill", tint: AppTheme.danger)
                    }
                    episodesSection
                    playerNote
                }
                .padding(.top, 10)
                .padding(.bottom, 30)
                .frame(maxWidth: 1_080, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .refreshable {
                await model.reload()
            }

            if model.isResolving {
                resolvingOverlay
            }
        }
        .navigationTitle(model.drama.title)
        .appInlineNavigationTitle()
        .appTransparentNavigationChrome()
        .toolbar {
            ToolbarItemGroup(placement: .appTrailing) {
                ShareLink(item: "\(model.drama.title) · \(model.drama.sourceName)") {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("分享剧集")

                Menu {
                    followMenuContent
                } label: {
                    Image(systemName: followIconName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(follow.status(forDramaId: model.drama.id) == nil ? AppTheme.textPrimary : AppTheme.brand)
                }
                .accessibilityLabel("收藏")
            }
        }
        .task {
            await model.loadIfNeeded()
            await downloads.refresh()
            downloads.startPolling()
        }
        .onAppear {
            downloads.startPolling()
        }
        .onDisappear {
            downloads.stopPolling()
        }
        .appPlayerPresentation(item: $model.playback) { request in
            PlayerView(
                drama: model.drama,
                chapters: model.chapters,
                provider: model.provider,
                request: request
            )
        }
    }

    // MARK: - 头部

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                CoverImage(drama: model.drama)
                    .frame(width: 116, height: 174)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(AppTheme.stroke, lineWidth: 0.6)
                    }
                    .shadow(color: .black.opacity(0.12), radius: 8, y: 4)

                VStack(alignment: .leading, spacing: 8) {
                    Text(model.drama.title)
                        .font(.appTitle(25))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)

                    HStack(spacing: 8) {
                        SourceBadge(sourceId: model.drama.source, name: model.drama.sourceName)
                        if let release = model.drama.releaseText {
                            MetaPill(text: release)
                        }
                    }

                    Text(model.drama.metaLine)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(2)

                    if !model.drama.tagList.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(model.drama.tagList, id: \.self) { tag in
                                    MetaPill(text: tag, tint: AppTheme.textTertiary)
                                }
                            }
                        }
                        .padding(.top, 2)
                    }

                    if let entry = history.entry(forDramaId: model.drama.id), entry.progress > 0.01 {
                        HStack(spacing: 6) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 10, weight: .bold))
                            Text("\(entry.episodeLabel) · 已看 \(Int(entry.progress * 100))%")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundStyle(AppTheme.textTertiary)
                        .padding(.top, 2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            actionRow

            if let description = model.drama.description, !description.isEmpty {
                VStack(alignment: .leading, spacing: 7) {
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineSpacing(4)
                        .lineLimit(descriptionExpanded ? nil : 3)
                    if description.count > 72 {
                        Button {
                            withAnimation(AppTheme.standard) {
                                descriptionExpanded.toggle()
                            }
                        } label: {
                            HStack(spacing: 3) {
                                Text(descriptionExpanded ? "收起" : "展开全部")
                                Image(systemName: descriptionExpanded ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 9, weight: .bold))
                            }
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(AppTheme.brandSoft)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(14)
                .solidCard()
            }
        }
        .padding(.horizontal, AppTheme.contentPadding)
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            Button {
                Task { await model.resume() }
            } label: {
                HStack(spacing: 7) {
                    if model.isResolving {
                        ProgressView()
                            .controlSize(.small)
                            .tint(AppTheme.onBrand)
                    } else {
                        Image(systemName: "play.fill")
                            .font(.system(size: 13, weight: .black))
                    }
                    Text(model.resumeButtonTitle)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(BrandActionButtonStyle())
            .disabled(model.chapters.isEmpty || model.isResolving)
            .opacity(model.chapters.isEmpty ? 0.45 : 1)

            Button {
                toggleFollow()
            } label: {
                Image(systemName: followIconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(follow.status(forDramaId: model.drama.id) == nil ? AppTheme.textPrimary : AppTheme.brand)
                    .frame(width: 50, height: 50)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().strokeBorder(AppTheme.stroke, lineWidth: 0.8))
            }
            .buttonStyle(AppPressStyle())
            .accessibilityLabel("收藏")

            Menu {
                Button {
                    Task { await model.downloadAll() }
                } label: {
                    Label("下载全部", systemImage: "arrow.down.to.line")
                }
                Button {
                    isSelectingDownloads = true
                } label: {
                    Label("选择下载", systemImage: "checklist")
                }
            } label: {
                Image(systemName: "arrow.down")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .frame(width: 50, height: 50)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().strokeBorder(AppTheme.stroke, lineWidth: 0.8))
            }
            .buttonStyle(AppPressStyle())
            .disabled(model.chapters.isEmpty)
            .accessibilityLabel("下载")
        }
    }

    // MARK: - 选集

    private var episodesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("选集")
                        .font(.appSection())
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(episodeSubtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppTheme.textTertiary)
                }

                Spacer()

                if isSelectingDownloads {
                    Button("全选") { model.selectAllForDownload() }
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                    Button {
                        Task {
                            await model.downloadSelected()
                            isSelectingDownloads = false
                        }
                    } label: {
                        Text("下载 \(model.selectedForDownload.count)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(AppTheme.onBrand)
                            .padding(.horizontal, 12)
                            .frame(height: 30)
                            .background(AppTheme.brandGradient, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(model.selectedForDownload.isEmpty)
                    .opacity(model.selectedForDownload.isEmpty ? 0.5 : 1)
                    Button("取消") {
                        model.clearDownloadSelection()
                        isSelectingDownloads = false
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.textTertiary)
                } else {
                    Button {
                        withAnimation(AppTheme.standard) {
                            episodeAscending.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: episodeAscending ? "arrow.up.arrow.down" : "arrow.down.arrow.up")
                                .font(.system(size: 10, weight: .bold))
                            Text(episodeAscending ? "正序" : "倒序")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(AppTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppTheme.contentPadding)

            if model.isLoading {
                episodeSkeleton
            } else if model.chapters.isEmpty {
                EmptyStateView(
                    systemImage: "list.bullet.rectangle.portrait",
                    title: model.errorMessage == nil ? "暂无选集" : "选集加载失败",
                    message: model.errorMessage ?? "下拉刷新试试。",
                    actionTitle: model.errorMessage == nil ? nil : "重试",
                    action: model.errorMessage == nil ? nil : { Task { await model.loadIfNeeded() } }
                )
            } else {
                LazyVGrid(columns: episodeColumns, spacing: 8) {
                    ForEach(indexedChapters) { item in
                        EpisodeChip(
                            number: item.index + 1,
                            title: episodeTitle(item.chapter, index: item.index),
                            isCurrent: history.entry(forDramaId: model.drama.id)?.episodeIndex == item.index + 1,
                            isDownloaded: model.isDownloaded(item.chapter),
                            isSelecting: isSelectingDownloads,
                            isSelected: model.selectedForDownload.contains(item.chapter.id)
                        ) {
                            if isSelectingDownloads {
                                model.toggleDownloadSelection(item.chapter)
                            } else {
                                Task { await model.play(chapter: item.chapter) }
                            }
                        }
                        .contextMenu {
                            Button {
                                Task { await model.download(chapter: item.chapter) }
                            } label: {
                                Label("下载本集", systemImage: "arrow.down.circle")
                            }
                            Button {
                                Task { await model.play(chapter: item.chapter) }
                            } label: {
                                Label("播放本集", systemImage: "play.circle")
                            }
                        }
                    }
                }
                .padding(.horizontal, AppTheme.contentPadding)

                if model.downloadedCount > 0 && !isSelectingDownloads {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(AppTheme.mint)
                        Text("已缓存 \(model.downloadedCount) 集，可离线播放")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                    .padding(.horizontal, AppTheme.contentPadding)
                }
            }
        }
    }

    private var episodeSubtitle: String {
        var parts: [String] = []
        if !model.chapters.isEmpty { parts.append("共 \(model.chapters.count) 集") }
        if let entry = history.entry(forDramaId: model.drama.id) {
            parts.append("上次看到第 \(entry.episodeIndex) 集")
        }
        if model.downloadedCount > 0 { parts.append("已存 \(model.downloadedCount) 集") }
        return parts.isEmpty ? "选择一集开始播放" : parts.joined(separator: " · ")
    }

    private var indexedChapters: [IndexedChapter] {
        let list = model.chapters.enumerated().map {
            IndexedChapter(index: $0.offset, chapter: $0.element)
        }
        return episodeAscending ? list : Array(list.reversed())
    }

    private func episodeTitle(_ chapter: Chapter, index: Int) -> String {
        if let value = chapter.currentEpisode, !value.isEmpty {
            if value.allSatisfy(\.isNumber) { return "第\(value)集" }
            return value
        }
        return "第\(index + 1)集"
    }

    private var episodeSkeleton: some View {
        LazyVGrid(columns: episodeColumns, spacing: 8) {
            ForEach(0..<12, id: \.self) { _ in
                SkeletonBlock(radius: 10)
                    .frame(height: 44)
            }
        }
        .padding(.horizontal, AppTheme.contentPadding)
    }

    // MARK: - 其他

    private var playerNote: some View {
        HStack(spacing: 7) {
            Image(systemName: "airplayvideo")
                .font(.system(size: 11, weight: .semibold))
            Text("Apple 原生播放 · 支持画中画、AirPlay、后台播放与自动连播")
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundStyle(AppTheme.textTertiary)
        .padding(.horizontal, AppTheme.contentPadding)
    }

    private var resolvingOverlay: some View {
        VStack(spacing: 10) {
            ProgressView()
                .tint(.white)
            Text("正在解析播放地址…")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(AppTheme.stroke, lineWidth: 0.8)
        }
        .shadow(color: .black.opacity(0.35), radius: 22, y: 10)
        .frame(maxHeight: .infinity, alignment: .center)
    }

    private func notice(text: String, icon: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(tint)
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(4)
            Spacer(minLength: 0)
        }
        .padding(11)
        .background(AppTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(AppTheme.stroke, lineWidth: 0.7)
        }
        .padding(.horizontal, AppTheme.contentPadding)
    }

    private var followIconName: String {
        switch follow.status(forDramaId: model.drama.id) {
        case .planned: return "heart.fill"
        case .watched: return "checkmark.circle.fill"
        case .watching, .none: return "heart"
        }
    }

    @ViewBuilder
    private var followMenuContent: some View {
        Button {
            follow.setStatus(.planned, for: model.drama)
        } label: {
            Label("想看", systemImage: "heart")
        }
        Button {
            follow.setStatus(.watching, for: model.drama)
        } label: {
            Label("在看", systemImage: "play.circle")
        }
        Button {
            follow.setStatus(.watched, for: model.drama)
        } label: {
            Label("已看完", systemImage: "checkmark.circle")
        }
        if follow.status(forDramaId: model.drama.id) != nil {
            Divider()
            Button(role: .destructive) {
                follow.remove(dramaId: model.drama.id)
            } label: {
                Label("取消标记", systemImage: "trash")
            }
        }
    }

    private func toggleFollow() {
        if follow.status(forDramaId: model.drama.id) == nil {
            follow.setStatus(.planned, for: model.drama)
        } else {
            follow.remove(dramaId: model.drama.id)
        }
    }
}

// MARK: - 选集按钮

private struct IndexedChapter: Identifiable {
    let index: Int
    let chapter: Chapter
    var id: String { chapter.id }
}

private struct EpisodeChip: View {
    let number: Int
    let title: String
    let isCurrent: Bool
    let isDownloaded: Bool
    let isSelecting: Bool
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(background)
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: isCurrent || isSelected ? 1.2 : 0.7)

                VStack(spacing: 1) {
                    Text(title)
                        .font(.system(size: 12, weight: isSelected || isCurrent ? .bold : .semibold))
                        .foregroundStyle(foreground)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    if isDownloaded {
                        Text("已缓存")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(isSelected ? AppTheme.onBrand.opacity(0.7) : AppTheme.mint)
                    }
                }
                .padding(.horizontal, 5)
            }
            .frame(height: 44)
        }
        .buttonStyle(AppPressStyle(scale: 0.95))
        .accessibilityLabel("\(title)\(isDownloaded ? "，已缓存" : "")")
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
    }

    private var background: Color {
        if isSelected { return AppTheme.brand }
        if isCurrent { return AppTheme.brand.opacity(0.10) }
        return AppTheme.surfaceMuted
    }

    private var borderColor: Color {
        if isSelected { return AppTheme.brand }
        if isCurrent { return AppTheme.brand.opacity(0.55) }
        return AppTheme.stroke
    }

    private var foreground: Color {
        if isSelected { return AppTheme.onBrand }
        if isCurrent { return AppTheme.brandSoft }
        return AppTheme.textSecondary
    }
}
