import SwiftUI
import PlayXUI

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
        SettingsGlassPage {
            SettingsGlassSection("离线缓存") {
                HStack(spacing: 16) {
                    ZStack {
                        Circle().stroke(PXTheme.stroke, lineWidth: 7)
                        Circle()
                            .trim(from: 0, to: min(1, Double(downloads.totalBytes) / (8 * 1024 * 1024 * 1024)))
                            .stroke(PXTheme.accent, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Text("\(downloads.completedJobs.count)").font(.title3.weight(.bold))
                    }
                    .frame(width: 66, height: 66)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("已下载 \(downloads.completedJobs.count) 集").font(.body.weight(.semibold))
                        Text(PXFormat.byteCount(downloads.totalBytes)).font(.caption).foregroundStyle(.secondary)
                        if !downloads.activeJobs.isEmpty {
                            PXProgressBar(value: downloads.aggregateProgress, height: 3)
                                .frame(maxWidth: 180)
                        }
                    }
                    Spacer()
                    if !downloads.activeJobs.isEmpty {
                        Button { Task { await downloads.pauseAll() } } label: {
                            Image(systemName: "pause.circle")
                        }
                        .buttonStyle(.plain)
                    }
                }
                .settingsRow()
            }

            SettingsGlassSection("任务") {
                SettingsPickerRow("筛选", selection: $selection) {
                    Text("全部").tag(0)
                    Text("进行中").tag(1)
                    Text("已完成").tag(2)
                    Text("失败").tag(3)
                }
            }

            if jobs.isEmpty {
                SettingsGlassSection {
                    SettingsNote("没有下载任务。详情页可缓存单集或全集，由原生核心调度。")
                }
            } else {
                SettingsGlassSection("下载队列") {
                    ForEach(Array(jobs.enumerated()), id: \.element.id) { index, job in
                        if index > 0 { SettingsGlassDivider() }
                        jobRow(job)
                    }
                }
            }
        }
        .navigationTitle("下载")
        .pxInlineNavigationTitle()
        .onAppear { downloads.startPolling() }
        .onDisappear { downloads.stopPolling() }
    }

    private func jobRow(_ job: DownloadJob) -> some View {
        HStack(alignment: .top, spacing: 11) {
            PXRemoteImage(url: URL(string: job.drama.cover ?? ""), maxPixel: 240)
                .frame(width: 44, height: 66)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            VStack(alignment: .leading, spacing: 4) {
                Text(job.drama.title).font(.system(size: 13, weight: .semibold)).lineLimit(1)
                Text(job.chapter.title).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                PXProgressBar(value: job.progress, height: 3)
                HStack(spacing: 8) {
                    Text(stateTitle(job.state)).font(.caption2.weight(.bold))
                        .foregroundStyle(job.state == DownloadJob.stateFailed ? PXTheme.danger : PXTheme.mint)
                    Text(PXFormat.percent(job.progress)).font(.caption2.monospaced()).foregroundStyle(.secondary)
                    if job.total > 0 {
                        Text("\(PXFormat.byteCount(job.bytes)) / \(PXFormat.byteCount(job.total))")
                            .font(.caption2).foregroundStyle(.secondary)
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
                Image(systemName: "ellipsis").foregroundStyle(.secondary)
            }
            .fixedSize()
        }
        .settingsRow()
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
