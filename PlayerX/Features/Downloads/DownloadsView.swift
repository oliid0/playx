import SwiftUI

/// 下载 Tab：调度、断点续传、HLS 分片/密钥改写全部在 Go 核心里完成，
/// 这里只负责展示状态、发控制指令。2 秒轮询一次，页面消失就停止。
struct DownloadsView: View {
    @ObservedObject private var store = DownloadStore.shared
    @State private var filter: DownloadFilter = .all

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 16) {
                    summaryCard
                    filterBar

                    if filteredJobs.isEmpty {
                        emptyState
                    } else {
                        ForEach(filteredJobs) { job in
                            DownloadJobCard(job: job)
                        }
                    }
                }
                .padding(.horizontal, AppTheme.contentPadding)
                .padding(.top, 8)
                .padding(.bottom, 28)
                .frame(maxWidth: 980, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .refreshable { await store.refresh() }
        }
        .navigationTitle("下载")
        .appLargeNavigationTitle()
        .appTransparentNavigationChrome()
        .toolbar {
            ToolbarItem(placement: .appTrailing) {
                Menu {
                    Button {
                        Task { await store.pauseAll() }
                    } label: {
                        Label("全部暂停", systemImage: "pause.circle")
                    }
                    Button {
                        Task { await store.resumeAll() }
                    } label: {
                        Label("全部继续", systemImage: "play.circle")
                    }
                    Divider()
                    Button {
                        Task { await store.refresh() }
                    } label: {
                        Label("刷新状态", systemImage: "arrow.clockwise")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("下载队列操作")
            }
        }
        .task {
            await store.refresh()
            store.startPolling()
        }
        .onAppear { store.startPolling() }
        .onDisappear { store.stopPolling() }
        .alert("下载出错", isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { shown in if !shown { store.errorMessage = nil } }
        )) {
            Button("好") { store.errorMessage = nil }
        } message: {
            Text(store.errorMessage ?? "")
        }
    }

    private var filteredJobs: [DownloadJob] {
        switch filter {
        case .all:
            return store.jobs.sorted { $0.created > $1.created }
        case .active:
            return store.activeJobs.sorted { $0.created > $1.created }
        case .completed:
            return store.completedJobs.sorted { $0.created > $1.created }
        case .failed:
            return store.failedJobs.sorted { $0.created > $1.created }
        }
    }

    private var summaryCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.12), lineWidth: 5)
                    .frame(width: 60, height: 60)
                Circle()
                    .trim(from: 0, to: max(0.01, store.aggregateProgress))
                    .stroke(AppTheme.brandGradient, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                Text("\(Int(store.aggregateProgress * 100))%")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(store.activeJobs.isEmpty ? "下载队列空闲" : "正在下载 \(store.activeJobs.count) 个任务")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("已完成 \(store.completedJobs.count) · 本地 \(AppFormat.bytes(store.totalBytes))")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.textTertiary)
            }
            Spacer(minLength: 4)
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(AppTheme.brand.opacity(0.9))
        }
        .padding(16)
        .solidCard()
    }

    private var filterBar: some View {
        HStack(spacing: 8) {
            ForEach(DownloadFilter.allCases) { item in
                let selected = filter == item
                Button {
                    withAnimation(AppTheme.quick) { filter = item }
                } label: {
                    HStack(spacing: 5) {
                        Text(item.title)
                        if item != .all {
                            Text("\(item.count(in: store))")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(selected ? AppTheme.onBrand.opacity(0.65) : AppTheme.textTertiary)
                        }
                    }
                    .font(.system(size: 12, weight: selected ? .bold : .medium))
                    .foregroundStyle(selected ? AppTheme.onBrand : AppTheme.textSecondary)
                    .padding(.horizontal, 12)
                    .frame(height: 32)
                    .background {
                        Capsule().fill(selected ? AnyShapeStyle(AppTheme.brandGradient) : AnyShapeStyle(AppTheme.surfaceMuted))
                    }
                    .overlay {
                        Capsule().strokeBorder(selected ? Color.clear : AppTheme.stroke, lineWidth: 0.7)
                    }
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
    }

    private var emptyState: some View {
        EmptyStateView(
            systemImage: filter == .all ? "arrow.down.circle" : "line.3.horizontal.decrease.circle",
            title: filter == .all ? "还没有下载任务" : "这个筛选下没有任务",
            message: filter == .all
                ? "在剧集详情页点「下载」，任务会交给 Go 核心排队、断点续传。"
                : "切换上面的筛选看看其他状态。"
        )
        .padding(.top, 20)
    }
}

private enum DownloadFilter: String, CaseIterable, Identifiable {
    case all, active, completed, failed
    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "全部"
        case .active: return "进行中"
        case .completed: return "已完成"
        case .failed: return "失败"
        }
    }

    @MainActor
    func count(in store: DownloadStore) -> Int {
        switch self {
        case .all: return store.jobs.count
        case .active: return store.activeJobs.count
        case .completed: return store.completedJobs.count
        case .failed: return store.failedJobs.count
        }
    }
}

private struct DownloadJobCard: View {
    let job: DownloadJob
    @ObservedObject private var store = DownloadStore.shared

    private var descriptor: SourceDescriptor? {
        SourceRegistry.descriptor(for: job.drama.source)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let descriptor {
                NavigationLink {
                    DetailView(provider: descriptor.provider, drama: job.drama)
                } label: {
                    rowContent
                }
                .buttonStyle(AppPressStyle())
            } else {
                rowContent
            }

            trailingActions
        }
        .padding(12)
        .solidCard()
        .contextMenu {
            Button {
                Task { await store.control(jobId: job.id, command: "remove") }
            } label: {
                Label("删除任务", systemImage: "trash")
            }
        }
    }

    private var rowContent: some View {
        HStack(alignment: .top, spacing: 12) {
            CoverImage(drama: job.drama)
                .frame(width: 54, height: 81)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.7)
                }

            VStack(alignment: .leading, spacing: 5) {
                Text(job.drama.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)

                Text("第 \(job.index) 集 · \(stateLabel)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(stateColor)

                if job.state == DownloadJob.stateDownloading || job.state == DownloadJob.stateQueued || job.state == DownloadJob.statePaused {
                    ProgressTrack(progress: job.progress, height: 3)
                        .padding(.top, 2)
                    HStack(spacing: 4) {
                        Text("\(Int(min(max(job.progress, 0), 1) * 100))%")
                        Text("·")
                        Text("\(AppFormat.bytes(job.bytes)) / \(AppFormat.bytes(job.total))")
                    }
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(AppTheme.textTertiary)
                }

                if let error = job.error, !error.isEmpty, job.state == DownloadJob.stateFailed {
                    Text(error)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(AppTheme.danger)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var trailingActions: some View {
        VStack(spacing: 8) {
            switch job.state {
            case DownloadJob.stateDownloading, DownloadJob.stateQueued:
                actionButton("pause.fill", tint: AppTheme.textPrimary) {
                    Task { await store.control(jobId: job.id, command: "pause") }
                }
            case DownloadJob.statePaused:
                actionButton("play.fill", tint: AppTheme.mint) {
                    Task { await store.control(jobId: job.id, command: "resume") }
                }
            case DownloadJob.stateFailed:
                actionButton("arrow.clockwise", tint: AppTheme.warning) {
                    Task { await store.control(jobId: job.id, command: "resume") }
                }
            case DownloadJob.stateCompleted:
                if let descriptor {
                    NavigationLink {
                        DetailView(provider: descriptor.provider, drama: job.drama)
                    } label: {
                        Image(systemName: "play.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(AppTheme.onBrand)
                            .frame(width: 32, height: 32)
                            .background(AppTheme.brandGradient, in: Circle())
                    }
                    .buttonStyle(AppPressStyle())
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(AppTheme.mint)
                        .frame(width: 32, height: 32)
                }
            default:
                ProgressView()
                    .controlSize(.small)
                    .frame(width: 32, height: 32)
            }

            Menu {
                Button {
                    Task { await store.control(jobId: job.id, command: "remove") }
                } label: {
                    Label("删除任务", systemImage: "trash")
                }
                if job.state == DownloadJob.stateCompleted {
                    Button {
                        Task { await store.control(jobId: job.id, command: "archive") }
                    } label: {
                        Label("归档", systemImage: "archivebox")
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.textTertiary)
                    .frame(width: 32, height: 24)
            }
        }
    }

    private func actionButton(_ systemImage: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 32, height: 32)
                .background(AppTheme.surface, in: Circle())
                .overlay(Circle().strokeBorder(AppTheme.stroke, lineWidth: 0.7))
        }
        .buttonStyle(AppPressStyle())
    }

    private var stateLabel: String {
        switch job.state {
        case DownloadJob.stateQueued: return "排队中"
        case DownloadJob.stateDownloading: return "下载中"
        case DownloadJob.statePaused: return "已暂停"
        case DownloadJob.stateFailed: return "失败"
        case DownloadJob.stateCompleted: return "已完成 · 可离线播放"
        case DownloadJob.stateRemoving: return "删除中"
        default: return job.state
        }
    }

    private var stateColor: Color {
        switch job.state {
        case DownloadJob.stateDownloading: return AppTheme.brand
        case DownloadJob.stateCompleted: return AppTheme.mint
        case DownloadJob.stateFailed: return AppTheme.danger
        case DownloadJob.statePaused: return AppTheme.textTertiary
        default: return AppTheme.textSecondary
        }
    }
}
