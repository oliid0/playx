import SwiftUI

struct PXDownloadsView: View {
    @ObservedObject private var downloads = DownloadStore.shared
    @State private var selection = 0

    private var jobs: [DownloadJob] {
        switch selection {
        case 1: downloads.activeJobs
        case 2: downloads.completedJobs
        case 3: downloads.failedJobs
        default: downloads.jobs
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                storageSummary
                Picker("", selection: $selection) {
                    Text("全部").tag(0)
                    Text("进行中").tag(1)
                    Text("已完成").tag(2)
                    Text("失败").tag(3)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, PXTheme.contentPadding)
                if jobs.isEmpty {
                    PXEmptyState(title: "没有下载任务", message: "详情页可以缓存单集或全集，下载由原生核心调度。", symbol: "arrow.down.circle")
                } else {
                    VStack(spacing: 10) {
                        ForEach(jobs) { job in
                            jobRow(job)
                        }
                    }
                    .padding(.horizontal, PXTheme.contentPadding)
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(PXPageBackground())
        .navigationTitle("下载")
        .pxInlineNavigationTitle()
        .onAppear { downloads.startPolling() }
        .onDisappear { downloads.stopPolling() }
    }

    private var storageSummary: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().stroke(.white.opacity(0.10), lineWidth: 7)
                Circle()
                    .trim(from: 0, to: min(1, Double(downloads.totalBytes) / (8 * 1024 * 1024 * 1024)))
                    .stroke(PXTheme.accent, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(downloads.completedJobs.count)")
                    .font(PXFont.display(22))
                    .foregroundStyle(PXTheme.textPrimary)
            }
            .frame(width: 74, height: 74)
            VStack(alignment: .leading, spacing: 3) {
                Text("离线缓存").font(PXFont.section(17)).foregroundStyle(PXTheme.textPrimary)
                Text("已下载 \(downloads.completedJobs.count) 集 · \(PXFormat.byteCount(downloads.totalBytes))")
                    .font(.system(size: 10)).foregroundStyle(PXTheme.textTertiary)
                if downloads.activeJobs.isEmpty {
                    Text("当前没有进行中的任务").font(.system(size: 9)).foregroundStyle(PXTheme.textTertiary)
                } else {
                    PXProgressBar(value: downloads.aggregateProgress, height: 3)
                        .frame(maxWidth: 180)
                }
            }
            Spacer()
            if !downloads.activeJobs.isEmpty {
                Button { Task { await downloads.pauseAll() } } label: {
                    Image(systemName: "pause.circle")
                }
                .buttonStyle(PXIconButtonStyle(size: 40))
            }
        }
        .pxFlatCard()
        .padding(.horizontal, PXTheme.contentPadding)
    }

    private func jobRow(_ job: DownloadJob) -> some View {
        HStack(alignment: .top, spacing: 11) {
            PXRemoteImage(url: URL(string: job.drama.cover ?? ""), maxPixel: 240)
                .frame(width: 48, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 7))
            VStack(alignment: .leading, spacing: 4) {
                Text(job.drama.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(PXTheme.textPrimary)
                    .lineLimit(1)
                Text(job.chapter.title)
                    .font(.system(size: 10))
                    .foregroundStyle(PXTheme.textTertiary)
                PXProgressBar(value: job.progress, height: 3)
                HStack(spacing: 8) {
                    Text(stateTitle(job.state))
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(job.state == DownloadJob.stateFailed ? PXTheme.danger : PXTheme.mint)
                    Text(PXFormat.percent(job.progress))
                        .font(PXFont.mono(9)).foregroundStyle(PXTheme.textTertiary)
                    if job.total > 0 {
                        Text("\(PXFormat.byteCount(job.bytes)) / \(PXFormat.byteCount(job.total))")
                            .font(.system(size: 9)).foregroundStyle(PXTheme.textTertiary)
                    }
                }
            }
            Spacer()
            Menu {
                if job.state == DownloadJob.stateDownloading || job.state == DownloadJob.stateQueued {
                    Button("暂停") { Task { await downloads.control(jobId: job.id, command: "pause") } }
                }
                if job.state == DownloadJob.statePaused || job.state == DownloadJob.stateFailed {
                    Button("继续") { Task { await downloads.control(jobId: job.id, command: "resume") } }
                }
                Button("删除", role: .destructive) { Task { await downloads.control(jobId: job.id, command: "remove") } }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(PXTheme.textTertiary)
            }
        }
        .padding(10)
        .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 11))
    }

    private func stateTitle(_ state: String) -> String {
        switch state {
        case DownloadJob.stateDownloading: "下载中"
        case DownloadJob.stateQueued: "排队中"
        case DownloadJob.statePaused: "已暂停"
        case DownloadJob.stateCompleted: "已完成"
        case DownloadJob.stateFailed: "失败"
        default: state
        }
    }
}
