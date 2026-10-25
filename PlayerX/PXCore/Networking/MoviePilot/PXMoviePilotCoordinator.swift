import Foundation
import Combine

@MainActor
final class PXMoviePilotCoordinator: ObservableObject {
    static let shared = PXMoviePilotCoordinator()

    @Published private(set) var user: PXMoviePilotUser?
    @Published private(set) var mediaResults: [PXMoviePilotMedia] = []
    @Published private(set) var torrents: [PXMoviePilotTorrent] = []
    @Published private(set) var subscriptions: [PXMoviePilotSubscription] = []
    @Published private(set) var downloads: [PXMoviePilotDownload] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isSearchingTorrents = false
    @Published var errorMessage: String?

    private let client: PXMoviePilotClient
    private let settings: PXAppSettings
    private var pollingTask: Task<Void, Never>?

    init(client: PXMoviePilotClient = PXMoviePilotClient(), settings: PXAppSettings = .shared) {
        self.client = client
        self.settings = settings
    }

    var isConfigured: Bool { settings.effectiveMoviePilotURL != nil }
    var isLoggedIn: Bool { !settings.moviePilotToken.isEmpty }

    func restoreSession() async {
        guard isConfigured else { return }
        if settings.moviePilotToken.isEmpty,
           !settings.moviePilotUsername.isEmpty, !settings.moviePilotPassword.isEmpty {
            await login(username: settings.moviePilotUsername, password: settings.moviePilotPassword)
        } else if !settings.moviePilotToken.isEmpty {
            await loadUser()
        }
    }

    func login(username: String, password: String, baseURL: String? = nil) async {
        guard let baseURL = baseURL.flatMap(Self.normalizedURL) ?? settings.effectiveMoviePilotURL else {
            errorMessage = "请先填写 MoviePilot 地址"
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let token = try await client.login(baseURL: baseURL, username: username, password: password)
            settings.moviePilotToken = token
            settings.moviePilotUsername = username
            settings.moviePilotPassword = password
            settings.moviePilotURL = baseURL.absoluteString
            user = try await client.currentUser(baseURL: baseURL, token: token)
            errorMessage = nil
            await reloadAll()
        } catch {
            errorMessage = "登录失败：\(error.localizedDescription)"
        }
    }

    func logout() {
        pollingTask?.cancel()
        settings.moviePilotToken = ""
        user = nil
        subscriptions = []
        downloads = []
    }

    func loadUser() async {
        guard let baseURL = settings.effectiveMoviePilotURL else { return }
        do {
            user = try await client.currentUser(baseURL: baseURL, token: settings.moviePilotToken)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func searchMedia(_ title: String) async {
        guard let baseURL = settings.effectiveMoviePilotURL, !settings.moviePilotToken.isEmpty else {
            errorMessage = "请先在设置中登录 MoviePilot"
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            mediaResults = try await client.searchMedia(
                baseURL: baseURL, token: settings.moviePilotToken, title: title
            )
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func searchTorrents(for media: PXMoviePilotMedia) async {
        guard let baseURL = settings.effectiveMoviePilotURL, !settings.moviePilotToken.isEmpty else {
            errorMessage = "请先在设置中登录 MoviePilot"
            return
        }
        isSearchingTorrents = true
        torrents = []
        defer { isSearchingTorrents = false }
        do {
            torrents = try await client.searchTorrents(
                baseURL: baseURL,
                token: settings.moviePilotToken,
                title: media.title,
                media: media
            )
            errorMessage = torrents.isEmpty ? "没有找到可用资源" : nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func download(_ torrent: PXMoviePilotTorrent, media: PXMoviePilotMedia?) async {
        guard let baseURL = settings.effectiveMoviePilotURL else { return }
        do {
            try await client.addDownload(
                baseURL: baseURL,
                token: settings.moviePilotToken,
                media: media,
                torrent: torrent
            )
            await loadDownloads()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func subscribe(_ media: PXMoviePilotMedia, season: Int? = nil) async {
        guard let baseURL = settings.effectiveMoviePilotURL else { return }
        do {
            try await client.addSubscription(
                baseURL: baseURL,
                token: settings.moviePilotToken,
                media: media,
                season: season
            )
            await loadSubscriptions()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteSubscription(_ subscription: PXMoviePilotSubscription) async {
        guard let baseURL = settings.effectiveMoviePilotURL else { return }
        do {
            try await client.deleteSubscription(
                baseURL: baseURL, token: settings.moviePilotToken, id: subscription.id
            )
            subscriptions.removeAll { $0.id == subscription.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func reloadAll() async {
        async let subs: Void = loadSubscriptions()
        async let downs: Void = loadDownloads()
        _ = await (subs, downs)
    }

    func loadSubscriptions() async {
        guard let baseURL = settings.effectiveMoviePilotURL, !settings.moviePilotToken.isEmpty else { return }
        do {
            subscriptions = try await client.subscriptions(
                baseURL: baseURL, token: settings.moviePilotToken
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadDownloads() async {
        guard let baseURL = settings.effectiveMoviePilotURL, !settings.moviePilotToken.isEmpty else { return }
        do {
            downloads = try await client.downloads(
                baseURL: baseURL, token: settings.moviePilotToken
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func startPolling() {
        pollingTask?.cancel()
        pollingTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                await self?.loadDownloads()
                try? await Task.sleep(nanoseconds: 5_000_000_000)
            }
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    func clearTorrents() {
        torrents = []
        errorMessage = nil
    }

    nonisolated private static func normalizedURL(_ raw: String) -> URL? {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }
        if let url = URL(string: value), url.scheme != nil { return url }
        return URL(string: "https://\(value)")
    }
}
