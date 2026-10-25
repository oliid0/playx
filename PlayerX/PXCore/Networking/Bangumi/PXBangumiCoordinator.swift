import Foundation
import Combine

@MainActor
final class PXBangumiCoordinator: ObservableObject {
    static let shared = PXBangumiCoordinator()
    static let authenticationRequired = Notification.Name("playerx.bangumi.authRequired")

    @Published private(set) var calendar: [PXBangumiCalendarDay] = []
    @Published private(set) var profile: PXBangumiUser?
    @Published private(set) var collections: [PXBangumiCollection] = []
    @Published private(set) var searchResults: [PXBangumiSubject] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let client: PXBangumiClient
    private let settings: PXAppSettings

    init(client: PXBangumiClient = PXBangumiClient(), settings: PXAppSettings = .shared) {
        self.client = client
        self.settings = settings
    }

    var isLoggedIn: Bool {
        !settings.bangumiAccessToken.isEmpty && profile != nil
    }

    var today: PXBangumiCalendarDay? {
        let weekday = Calendar.current.component(.weekday, from: Date())
        // Bangumi weekday: 1=Mon … 7=Sun；Calendar: 1=Sun … 7=Sat。
        let bangumiWeekday = weekday == 1 ? 7 : weekday - 1
        return calendar.first { $0.weekday.id == bangumiWeekday } ?? calendar.first
    }

    func loadCalendarIfNeeded() async {
        guard calendar.isEmpty else { return }
        await loadCalendar()
    }

    func loadCalendar() async {
        isLoading = true
        defer { isLoading = false }
        do {
            calendar = try await client.calendar()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restoreSession() async {
        guard !settings.bangumiAccessToken.isEmpty else { return }
        do {
            profile = try await client.me(token: settings.bangumiAccessToken)
            if settings.bangumiUsername.isEmpty, let name = profile?.username {
                settings.bangumiUsername = name
            }
            await loadCollections()
        } catch {
            profile = nil
            errorMessage = error.localizedDescription
        }
    }

    func login(token: String, username: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let user = try await client.me(token: token)
            settings.bangumiAccessToken = token
            settings.bangumiUsername = username.isEmpty ? user.username : username
            profile = user
            errorMessage = nil
            await loadCollections()
        } catch {
            errorMessage = "登录失败：\(error.localizedDescription)"
        }
    }

    func logout() {
        settings.bangumiAccessToken = ""
        profile = nil
        collections = []
    }

    func search(_ keyword: String, type: PXBangumiSubjectType = .anime) async {
        guard !keyword.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            searchResults = try await client.search(keyword, type: type)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func subject(id: Int) async -> PXBangumiSubject? {
        do { return try await client.subject(id: id) }
        catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func episodes(subjectID: Int) async -> [PXBangumiEpisode] {
        (try? await client.episodes(subjectID: subjectID)) ?? []
    }

    func updateCollection(subjectID: Int, type: PXBangumiCollectionType?, rate: Int? = nil) async {
        let token = settings.bangumiAccessToken
        guard !token.isEmpty else {
            errorMessage = "请先在设置中登录 Bangumi"
            return
        }
        do {
            try await client.updateCollection(subjectID: subjectID, type: type, rate: rate, token: token)
            await loadCollections()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func markEpisode(_ episode: PXBangumiEpisode, watched: Bool) async {
        let token = settings.bangumiAccessToken
        guard !token.isEmpty else { return }
        do {
            try await client.updateEpisode(episodeID: episode.id, type: watched ? 2 : 0, token: token)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadCollections() async {
        guard !settings.bangumiUsername.isEmpty else { return }
        do {
            collections = try await client.collections(username: settings.bangumiUsername)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func collection(for subjectID: Int) -> PXBangumiCollection? {
        collections.first { $0.subjectID == subjectID }
    }
}
