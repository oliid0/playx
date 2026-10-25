import SwiftUI

/// 站源管理。默认可见站源直接列出，其余站源要密码解锁后显示。
/// 解锁是整个 App 维度的（不是分站源锁），和 guoapp-src 的行为一致。
struct SourcesView: View {
    @ObservedObject private var lock = SourceLockStore.shared
    @State private var showingLockSheet = false

    private var visibleSources: [SourceDescriptor] {
        SourceRegistry.all.filter(\.defaultVisible)
    }
    private var hiddenSources: [SourceDescriptor] {
        SourceRegistry.all.filter { !$0.defaultVisible }
    }

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    lockCard

                    sourceSection(title: "默认站源", subtitle: "打开 App 就能浏览", sources: visibleSources)

                    hiddenSection

                    Text("站源数据与播放解析由 Go 核心完成；这里只控制界面是否展示，不改变网络能力。")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppTheme.textTertiary)
                        .lineSpacing(3)
                        .padding(.horizontal, AppTheme.contentPadding)
                }
                .padding(.top, 8)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("站源管理")
        .appInlineNavigationTitle()
        .appTransparentNavigationChrome()
        .sheet(isPresented: $showingLockSheet) {
            SourceLockView()
        }
    }

    private var lockCard: some View {
        HStack(spacing: 13) {
            ZStack {
                Circle()
                    .fill(lock.isUnlockedThisLaunch ? AppTheme.mint.opacity(0.16) : AppTheme.surfaceStrong)
                    .frame(width: 48, height: 48)
                Image(systemName: lock.isUnlockedThisLaunch ? "lock.open.fill" : "lock.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(lock.isUnlockedThisLaunch ? AppTheme.mint : AppTheme.textSecondary)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(lock.hasPassword ? (lock.isUnlockedThisLaunch ? "隐藏站源已解锁" : "隐藏站源已加密") : "站源密码未设置")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(lock.isUnlockedThisLaunch ? "解锁状态仅在本次运行期间有效" : "设置 3-12 位数字密码，解锁 \(hiddenSources.count) 个额外站源")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.textTertiary)
                    .lineLimit(2)
            }
            Spacer(minLength: 4)

            Button {
                if lock.isUnlockedThisLaunch {
                    lock.lockAgain()
                } else {
                    showingLockSheet = true
                }
            } label: {
                Text(lock.isUnlockedThisLaunch ? "重新锁定" : (lock.hasPassword ? "解锁" : "设置"))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(.horizontal, 12)
                    .frame(height: 32)
                    .background(AppTheme.surface, in: Capsule())
                    .overlay(Capsule().strokeBorder(AppTheme.stroke, lineWidth: 0.7))
            }
            .buttonStyle(AppPressStyle())
        }
        .padding(14)
        .solidCard()
        .padding(.horizontal, AppTheme.contentPadding)
    }

    private func sourceSection(title: String, subtitle: String, sources: [SourceDescriptor]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: title, subtitle: subtitle)
                .padding(.horizontal, AppTheme.contentPadding)

            VStack(spacing: 8) {
                ForEach(sources) { descriptor in
                    NavigationLink {
                        DiscoverView(provider: descriptor.provider)
                    } label: {
                        SourceManagementRow(descriptor: descriptor, isLocked: false)
                    }
                    .buttonStyle(AppPressStyle())
                }
            }
            .padding(.horizontal, AppTheme.contentPadding)
        }
    }

    @ViewBuilder
    private var hiddenSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(
                title: "更多站源",
                subtitle: lock.isUnlockedThisLaunch ? "已解锁 \(hiddenSources.count) 个" : "密码解锁后显示"
            )
            .padding(.horizontal, AppTheme.contentPadding)

            if lock.isUnlockedThisLaunch {
                VStack(spacing: 8) {
                    ForEach(hiddenSources) { descriptor in
                        NavigationLink {
                            DiscoverView(provider: descriptor.provider)
                        } label: {
                            SourceManagementRow(descriptor: descriptor, isLocked: false)
                        }
                        .buttonStyle(AppPressStyle())
                    }
                }
                .padding(.horizontal, AppTheme.contentPadding)
            } else {
                Button {
                    showingLockSheet = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppTheme.textSecondary)
                            .frame(width: 44, height: 44)
                            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        VStack(alignment: .leading, spacing: 3) {
                            Text("解锁 \(hiddenSources.count) 个隐藏站源")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AppTheme.textPrimary)
                            Text("黄豆 / 剧果 / 野果 / 帝果 / 黄果系列")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(AppTheme.textTertiary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                    .padding(12)
                    .solidCard()
                }
                .buttonStyle(AppPressStyle())
                .padding(.horizontal, AppTheme.contentPadding)
            }
        }
    }
}

private struct SourceManagementRow: View {
    let descriptor: SourceDescriptor
    let isLocked: Bool

    private var style: SourceVisualStyle { SourceVisualStyle.style(for: descriptor.id) }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(style.gradient)
                Image(systemName: style.symbol)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 3) {
                Text(descriptor.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(style.tagline)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.textTertiary)
                    .lineLimit(1)
            }
            Spacer()
            if isLocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.textTertiary)
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.textTertiary.opacity(0.8))
            }
        }
        .padding(12)
        .solidCard()
    }
}
