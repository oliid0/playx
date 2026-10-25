import Foundation
import Combine

@MainActor
final class PXDanmakuCoordinator: ObservableObject {
    @Published private(set) var comments: [PXDanmakuComment] = []
    @Published private(set) var currentEpisode: PXDanmakuEpisode?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published var timeOffset: Double = 0

    private let client = PXDanmakuClient()
    private let settings = PXAppSettings.shared
    private var cache: [String: [PXDanmakuComment]] = [:]
    private var task: Task<Void, Never>?

    func load(title: String, episodeNumber: Int, dramaID: String) {
        task?.cancel()
        let key = "\(dramaID)-ep\(episodeNumber)"
        if let cached = cache[key] {
            comments = cached
            currentEpisode = nil
            return
        }
        guard settings.danmakuAutoMatch else { return }
        guard let gateway = settings.effectiveDanmakuGateway else {
            errorMessage = "弹幕网关地址无效"
            return
        }
        isLoading = true
        errorMessage = nil
        comments = []
        task = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                guard let episode = try await self.client.episodes(
                    title: PXNormalizer.title(title).isEmpty ? title : title,
                    episodeNumber: episodeNumber,
                    gateway: gateway,
                    apiKey: self.settings.effectiveDanmakuKey
                ) else { throw PXDanmakuError.noMatch }
                let fetched = try await self.client.comments(
                    episodeID: episode.episodeID,
                    gateway: gateway,
                    apiKey: self.settings.effectiveDanmakuKey
                )
                guard !Task.isCancelled else { return }
                self.cache[key] = fetched
                self.currentEpisode = episode
                self.comments = fetched.sorted { $0.time < $1.time }
                self.isLoading = false
            } catch {
                guard !Task.isCancelled else { return }
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func clear() {
        task?.cancel()
        comments = []
        currentEpisode = nil
        errorMessage = nil
        isLoading = false
    }

    /// 当前时间应该出现的弹幕（用于覆盖层采样）。
    func active(at time: Double, window: Double = 8) -> [PXDanmakuComment] {
        let adjusted = time + timeOffset
        return comments.filter { $0.time <= adjusted && $0.time >= adjusted - window }
    }
}
