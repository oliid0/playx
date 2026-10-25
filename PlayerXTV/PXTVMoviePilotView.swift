import SwiftUI

struct PXTVMoviePilotView: View {
    @EnvironmentObject private var app: PXTVAppState
    @ObservedObject private var coordinator = PXMoviePilotCoordinator.shared
    @State private var query = ""
    @State private var showLogin = false
    @State private var selectedMedia: PXMoviePilotMedia?

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("MoviePilot").font(PXFont.display(44)).foregroundStyle(PXTheme.textPrimary)
                        Text("找片 · 下载 · 订阅").font(.body).foregroundStyle(PXTheme.textTertiary)
                    }
                    Spacer()
                    if coordinator.isLoggedIn {
                        Button("账号") { showLogin = true }.buttonStyle(.card)
                    } else {
                        Button("连接服务器") { showLogin = true }.buttonStyle(PXTVPrimaryButtonStyle())
                    }
                }
                if !coordinator.isLoggedIn {
                    Text("在设置中填入 MoviePilot 地址与账号，即可在 Apple TV 上搜索站点资源并添加下载。")
                        .font(.body).foregroundStyle(PXTheme.textSecondary)
                        .frame(maxWidth: 900, alignment: .leading)
                } else {
                    HStack(spacing: 12) {
                        TextField("搜索片名", text: $query)
                            .textFieldStyle(.plain)
                            .font(.title3)
                            .padding(.horizontal, 16)
                            .frame(height: 52)
                            .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 10))
                            .onSubmit { Task { await coordinator.searchMedia(query) } }
                        Button("搜索") { Task { await coordinator.searchMedia(query) } }
                            .buttonStyle(PXTVPrimaryButtonStyle())
                    }
                    if coordinator.isLoading {
                        PXTVLoadingView(text: "搜索媒体")
                    } else if let media = selectedMedia {
                        resourceList(media)
                    } else if !coordinator.mediaResults.isEmpty {
                        LazyVStack(spacing: 10) {
                            ForEach(coordinator.mediaResults) { media in
                                Button {
                                    selectedMedia = media
                                    Task { await coordinator.searchTorrents(for: media) }
                                } label: {
                                    PXTVMediaPilotRow(media: media)
                                }
                                .buttonStyle(.card)
                            }
                        }
                    } else {
                        PXTVEmptyView(title: "开始找片", message: "输入片名，选中媒体后查看资源。", symbol: "paperplane")
                    }
                }
                if let error = coordinator.errorMessage {
                    Text(error).font(.caption).foregroundStyle(PXTheme.warning)
                }
            }
            .padding(.horizontal, 56)
            .padding(.top, 46)
            .padding(.bottom, 60)
        }
        .task { await coordinator.restoreSession() }
        .sheet(isPresented: $showLogin) {
            PXTVMoviePilotLoginView()
        }
    }

    private func resourceList(_ media: PXMoviePilotMedia) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(media.title).font(PXFont.title(26)).foregroundStyle(PXTheme.textPrimary)
                Spacer()
                Button("返回") { selectedMedia = nil; coordinator.clearTorrents() }.buttonStyle(.card)
            }
            if coordinator.isSearchingTorrents {
                PXTVLoadingView(text: "聚合站点资源")
            } else if coordinator.torrents.isEmpty {
                PXTVEmptyView(title: "暂无资源", message: "MoviePilot 没搜到种子。", symbol: "tray")
            } else {
                ForEach(coordinator.torrents) { torrent in
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(torrent.title).font(.system(size: 16, weight: .semibold)).foregroundStyle(PXTheme.textPrimary).lineLimit(2)
                            HStack(spacing: 8) {
                                if let site = torrent.siteName { PXTag(text: site, tint: PXTheme.sky) }
                                if let size = torrent.sizeText { PXTag(text: size) }
                                if let seeders = torrent.seeders { Text("↑\(seeders)").font(.caption).foregroundStyle(PXTheme.mint) }
                            }
                        }
                        Spacer()
                        Button("下载") { Task { await coordinator.download(torrent, media: media) } }
                            .buttonStyle(PXTVPrimaryButtonStyle())
                    }
                    .padding(14)
                    .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
}

struct PXTVMediaPilotRow: View {
    let media: PXMoviePilotMedia
    var body: some View {
        HStack(spacing: 16) {
            PXRemoteImage(url: media.posterURL, maxPixel: 300)
                .frame(width: 80, height: 120).clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 4) {
                Text(media.title).font(.title3.weight(.semibold)).foregroundStyle(PXTheme.textPrimary)
                HStack(spacing: 6) {
                    if let year = media.year { PXTag(text: year) }
                    if let type = media.type { PXTag(text: type, tint: PXTheme.sky) }
                }
                if let overview = media.overview { Text(overview).font(.caption).foregroundStyle(PXTheme.textTertiary).lineLimit(2) }
            }
            Spacer()
        }
        .padding(10)
        .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct PXTVMoviePilotLoginView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var coordinator = PXMoviePilotCoordinator.shared
    @ObservedObject private var settings = PXAppSettings.shared
    @State private var baseURL = ""
    @State private var username = ""
    @State private var password = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("MoviePilot 账号").font(PXFont.display(34)).foregroundStyle(PXTheme.textPrimary)
            TextField("服务器地址", text: $baseURL)
                .textFieldStyle(.plain).padding(14).background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 10))
            TextField("用户名", text: $username)
                .textFieldStyle(.plain).padding(14).background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 10))
            SecureField("密码", text: $password)
                .textFieldStyle(.plain).padding(14).background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 10))
            HStack(spacing: 12) {
                Button("登录") {
                    Task {
                        await coordinator.login(username: username, password: password, baseURL: baseURL)
                        if coordinator.isLoggedIn { dismiss() }
                    }
                }
                .buttonStyle(PXTVPrimaryButtonStyle())
                Button("取消") { dismiss() }.buttonStyle(.card)
            }
            if let error = coordinator.errorMessage { Text(error).font(.caption).foregroundStyle(PXTheme.warning) }
        }
        .padding(56)
        .frame(maxWidth: 900)
        .background(PXPageBackground())
        .onAppear {
            baseURL = settings.moviePilotURL
            username = settings.moviePilotUsername
            password = settings.moviePilotPassword
        }
    }
}
