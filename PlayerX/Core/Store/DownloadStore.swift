import Foundation

/// 下载队列的 Swift 封装。调度、断点续传、HLS 分片/密钥改写全部在 Go 核心里
/// （`native/core/app_downloads.go`），这边只发控制指令、按固定节奏轮询状态——和 Dart 版
/// 的做法一样（Dart 侧 2 秒轮询一次），不在 Swift 里重做一套下载引擎。
@MainActor
final class DownloadStore: ObservableObject {
    static let shared = DownloadStore()

    @Published private(set) var jobs: [DownloadJob] = []
    @Published var errorMessage: String?

    private var pollTask: Task<Void, Never>?

    private init() {}

    /// 下载页可见时调用；离开页面调 `stopPolling()`，别一直轮询。
    func startPolling() {
        guard pollTask == nil else { return }
        pollTask = Task { [weak self] in
            while let self, !Task.isCancelled {
                await self.refresh()
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
    }

    func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
    }

    func refresh() async {
        struct Response: Decodable { let jobs: [DownloadJob] }
        do {
            let response: Response = try await NativeBridge.call(NativeRequest(action: "downloads"))
            jobs = response.jobs
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// 把 `episodes`（分集 + 在剧里的序号）加入下载队列。`force` 为 true 时会重试已失败/文件缺失的任务。
    @discardableResult
    func enqueue(drama: Drama, episodes: [(chapter: Chapter, index: Int)], quality: Int? = nil, force: Bool = false) async -> Int {
        struct Response: Decodable { let added: Int }
        let entries = episodes.map { DownloadEntry(chapter: $0.chapter, index: $0.index) }
        do {
            let response: Response = try await NativeBridge.call(
                NativeRequest(action: "enqueueDownloads", drama: drama, quality: quality, force: force, entries: entries)
            )
            await refresh()
            return response.added
        } catch {
            errorMessage = error.localizedDescription
            return 0
        }
    }

    /// `command`: pause / resume / remove / archive / restore
    func control(jobId: String, command: String) async {
        do {
            let _: Bool = try await NativeBridge.call(
                NativeRequest(action: "controlDownloads", jobId: jobId, command: command)
            )
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// 已下载完成的分集走本地文件播放，不用再联网解析。
    func localPlan(drama: Drama, index: Int) async throws -> PlaybackPlan {
        try await NativeBridge.call(NativeRequest(action: "localPlayback", drama: drama, index: index))
    }

    func job(dramaId: String, index: Int) -> DownloadJob? {
        jobs.first { $0.drama.id == dramaId && $0.index == index }
    }

    var activeJobs: [DownloadJob] {
        jobs.filter {
            $0.state == DownloadJob.stateDownloading
                || $0.state == DownloadJob.stateQueued
                || $0.state == DownloadJob.statePaused
        }
    }

    var completedJobs: [DownloadJob] {
        jobs.filter { $0.state == DownloadJob.stateCompleted }
    }

    var failedJobs: [DownloadJob] {
        jobs.filter { $0.state == DownloadJob.stateFailed }
    }

    var totalBytes: Int64 {
        jobs.reduce(0) { $0 + max($1.bytes, 0) }
    }

    var aggregateProgress: Double {
        let active = activeJobs
        guard !active.isEmpty else { return 0 }
        return active.reduce(0) { $0 + min(max($1.progress, 0), 1) } / Double(active.count)
    }

    /// 批量暂停/继续。逐条发控制指令，Go 核心没有批量 action（见 Architecture 的已知限制）。
    func pauseAll() async {
        for job in activeJobs where job.state != DownloadJob.statePaused {
            await control(jobId: job.id, command: "pause")
        }
    }

    func resumeAll() async {
        for job in jobs where job.state == DownloadJob.statePaused || job.state == DownloadJob.stateFailed {
            await control(jobId: job.id, command: "resume")
        }
    }
}
