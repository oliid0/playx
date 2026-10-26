import SwiftUI

struct PXSettingsHomeView: View {
    @EnvironmentObject private var app: PXAppState
    @ObservedObject private var player = PXPlayerPreferences.shared
    @ObservedObject private var settings = PXAppSettings.shared
    @ObservedObject private var bangumi = PXBangumiCoordinator.shared
    @ObservedObject private var moviePilot = PXMoviePilotCoordinator.shared

    var body: some View {
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("设置")
                            .font(PXFont.display(32))
                            .foregroundStyle(PXTheme.textPrimary)
                        Text("播放、元数据、媒体源与外部服务")
                            .font(PXFont.caption(11))
                            .foregroundStyle(PXTheme.textTertiary)
                    }
                    .padding(.bottom, 2)

                    PXSettingsSection(title: "播放") {
                        NavigationLink {
                            PXPlaybackSettingsView()
                        } label: {
                            PXSettingsRow(
                                symbol: "play.circle",
                                title: "播放内核与设置",
                                subtitle: "竖屏 Stories / 横屏章节 / 自动连播",
                                value: player.engine.title
                            )
                        }
                        .buttonStyle(.plain)
                        Divider().overlay(PXTheme.stroke)
                        NavigationLink {
                            PXDanmakuSettingsView()
                        } label: {
                            PXSettingsRow(
                                symbol: "text.bubble",
                                title: "弹幕",
                                subtitle: "弹弹play 匹配、字号、速度与轨道",
                                value: player.danmakuEnabled ? "开启" : "关闭"
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    PXSettingsSection(title: "元数据") {
                        NavigationLink {
                            PXTMDbSettingsView()
                        } label: {
                            PXSettingsRow(
                                symbol: "sparkles.tv",
                                title: "TMDB",
                                subtitle: "评分、简介、演员表、季集资料",
                                value: settings.tmdbEnabled ? "已开启" : "关闭"
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    PXSettingsSection(title: "服务") {
                        NavigationLink {
                            PXBangumiSettingsView()
                        } label: {
                            PXSettingsRow(
                                symbol: "calendar",
                                title: "Bangumi",
                                subtitle: "每日放送与追番进度",
                                value: bangumi.isLoggedIn ? "已登录" : "未登录",
                                tint: PXTheme.rose
                            )
                        }
                        .buttonStyle(.plain)
                        Divider().overlay(PXTheme.stroke)
                        NavigationLink {
                            PXMoviePilotSettingsView()
                        } label: {
                            PXSettingsRow(
                                symbol: "paperplane",
                                title: "MoviePilot",
                                subtitle: "找片、下载、订阅",
                                value: moviePilot.isLoggedIn ? "已登录" : "未连接",
                                tint: PXTheme.sky
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    PXSettingsSection(title: "内容") {
                        NavigationLink {
                            PXSourceSettingsView()
                        } label: {
                            PXSettingsRow(
                                symbol: "server.rack",
                                title: "站源与片库",
                                subtitle: "启用站源、密码锁、内容偏好",
                                value: "\(app.availableSources.count) 个"
                            )
                        }
                        .buttonStyle(.plain)
                        Divider().overlay(PXTheme.stroke)
                        NavigationLink {
                            PXDownloadsView()
                        } label: {
                            PXSettingsRow(
                                symbol: "arrow.down.circle",
                                title: "下载与缓存",
                                subtitle: "管理离线剧集与磁盘占用"
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    PXSettingsSection(title: "其他") {
                        NavigationLink {
                            PXAboutView()
                        } label: {
                            PXSettingsRow(
                                symbol: "info.circle",
                                title: "关于 PlayerX",
                                subtitle: "版本、开源许可与项目主页"
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    Text("PlayerX · \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(PXTheme.textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                }
                .padding(.horizontal, PXTheme.padding(for: proxy.size.width))
                .padding(.bottom, 36)
            }
        }
        .background(PXPageBackground())
        .navigationTitle("设置")
        .pxHiddenNavigationBar()
    }
}
