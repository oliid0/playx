import SwiftUI
import Combine
import Foundation

#if os(iOS)
import UIKit
#endif

/// App 的四个一级页面。iPhone 用系统 TabView，iPad 常规宽度和 macOS 用侧边栏。
/// 先用系统容器，不重写导航：iPad 分屏、macOS 窗口、键盘焦点、无障碍全都由系统负责。
enum AppSection: String, CaseIterable, Identifiable, Hashable {
    case home
    case follow
    case downloads
    case me

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "发现"
        case .follow: return "追剧"
        case .downloads: return "下载"
        case .me: return "设置"
        }
    }

    var subtitle: String {
        switch self {
        case .home: return "推荐与站源"
        case .follow: return "想看 / 在看 / 已看"
        case .downloads: return "离线缓存"
        case .me: return "播放、弹幕与数据"
        }
    }

    var icon: String {
        switch self {
        case .home: return "sparkles.tv"
        case .follow: return "heart.text.square"
        case .downloads: return "arrow.down.circle"
        case .me: return "gearshape"
        }
    }
}

struct RootView: View {
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    @State private var showingSearch = false
    @State private var showingOnboarding = false
    @AppStorage("playerx.onboarding.completed.v1") private var onboardingCompleted = false

    var body: some View {
        Group {
            #if os(macOS)
            SidebarShell()
            #else
            if Platform.isPad && horizontalSizeClass == .regular {
                SidebarShell()
            } else {
                PhoneTabShell()
            }
            #endif
        }
        .tint(.primary)
        .sheet(isPresented: $showingSearch) {
            GlobalSearchView()
        }
        .sheet(isPresented: $showingOnboarding, onDismiss: { onboardingCompleted = true }) {
            OnboardingView {
                onboardingCompleted = true
                showingOnboarding = false
            }
        }
        .onAppear {
            if !onboardingCompleted {
                showingOnboarding = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .playerXOpenSearch)) { _ in
            showingSearch = true
        }
    }
}

// MARK: - iPhone：系统 TabView

#if os(iOS)
private struct PhoneTabShell: View {
    var body: some View {
        TabView {
            NavigationStack { HomeView() }
                .tabItem { Label("发现", systemImage: "sparkles.tv") }

            NavigationStack { FollowView() }
                .tabItem { Label("追剧", systemImage: "heart.text.square") }

            NavigationStack { DownloadsView() }
                .tabItem { Label("下载", systemImage: "arrow.down.circle") }

            NavigationStack { MeView() }
                .tabItem { Label("设置", systemImage: "gearshape") }
        }
    }


}
#endif

// MARK: - iPad 常规宽度 / macOS：侧边栏

private struct SidebarShell: View {
    @State private var selection: AppSection? = .home

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection)
                .navigationSplitViewColumnWidth(min: 218, ideal: 244, max: 292)
        } detail: {
            NavigationStack {
                detail(for: selection ?? .home)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .background(AppTheme.background)
    }

    @ViewBuilder
    private func detail(for section: AppSection) -> some View {
        switch section {
        case .home: HomeView()
        case .follow: FollowView()
        case .downloads: DownloadsView()
        case .me: MeView()
        }
    }
}

private struct SidebarView: View {
    @Binding var selection: AppSection?

    var body: some View {
        VStack(spacing: 0) {
            brandHeader
            List(selection: $selection) {
                Section {
                    ForEach(AppSection.allCases) { section in
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(section.title)
                                    .font(.system(size: 13, weight: .semibold))
                                Text(section.subtitle)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(AppTheme.textTertiary)
                            }
                        } icon: {
                            Image(systemName: section.icon)
                                .foregroundStyle(selection == section ? AppTheme.brand : AppTheme.textSecondary)
                        }
                        .padding(.vertical, 3)
                        .tag(section)
                    }
                } header: {
                    Text("浏览")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppTheme.textTertiary)
                }
            }
            #if os(macOS)
            .listStyle(.sidebar)
            #else
            .listStyle(.insetGrouped)
            #endif
            .scrollContentBackground(.hidden)

            sidebarFooter
        }
        .background(AppBackground())
        .navigationTitle("PlayerX")
    }

    private var brandHeader: some View {
        HStack(spacing: 11) {
            AppMark(size: 42)
            VStack(alignment: .leading, spacing: 2) {
                Text("PlayerX")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("原生短剧播放器")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(AppTheme.textTertiary)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 12)
    }

    private var sidebarFooter: some View {
        VStack(alignment: .leading, spacing: 6) {
            Divider().overlay(AppTheme.stroke)
            HStack(spacing: 6) {
                Image(systemName: "airplayvideo")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(AppTheme.mint)
                Text("AVPlayer 原生播放")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(AppTheme.textTertiary)
                Spacer()
            }
            Text("v\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(AppTheme.textTertiary.opacity(0.7))
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }
}
