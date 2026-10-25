import SwiftUI

/// 首次启动的品牌欢迎页。只出现一次，不阻塞后续使用；iPad / Mac 用同一套内容。
struct OnboardingView: View {
    let onFinish: () -> Void

    @State private var page = 0

    private struct Page {
        let symbol: String
        let title: String
        let subtitle: String
        let features: [(String, String)]
    }

    private let pages: [Page] = [
        Page(
            symbol: "sparkles.tv",
            title: "一个播放器\n装下所有短剧",
            subtitle: "多站源聚合，首页、追剧、下载和搜索都在一个 App 里。",
            features: [
                ("square.stack.3d.up.fill", "11 个站源，按需解锁"),
                ("heart.text.square.fill", "追剧 / 在看 / 已看完"),
                ("laptopcomputer.and.iphone", "iPhone · iPad · Mac")
            ]
        ),
        Page(
            symbol: "play.rectangle.on.rectangle",
            title: "播放，\n按你的习惯来",
            subtitle: "Apple 原生播放链路，字幕、音轨、清晰度和画中画都跟着系统走。",
            features: [
                ("captions.bubble.fill", "原生字幕 / CC / 音轨"),
                ("4k.tv.fill", "清晰度切换，保留进度"),
                ("pip.fill", "画中画 · AirPlay · 后台播放")
            ]
        ),
        Page(
            symbol: "slider.horizontal.3",
            title: "细节，\n都能调",
            subtitle: "从跳过间隔到弹幕样式，设置页会记住你的每一次选择。",
            features: [
                ("goforward.15", "跳过间隔与 HUD 常显"),
                ("text.bubble.fill", "弹幕字号 / 速度 / 行数"),
                ("arrow.down.circle.fill", "下载清晰度与缓存清理")
            ]
        )
    ]

    var body: some View {
        ZStack {
            AppBackground()

            RadialGradient(
                colors: [AppTheme.brand.opacity(0.18), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 520
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    AppMark(size: 34)
                    Text("PlayerX")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Button("跳过") { finish() }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.textTertiary)
                        .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                #if os(iOS)
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { index in
                        pageView(pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(AppTheme.standard, value: page)
                #else
                ZStack {
                    pageView(pages[page])
                        .id(page)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
                .animation(AppTheme.standard, value: page)
                #endif

                footer
            }
        }
        #if os(macOS)
        .frame(width: 620, height: 650)
        #endif
    }

    private func pageView(_ page: Page) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 22) {
                ZStack {
                    Circle()
                        .fill(AppTheme.brand.opacity(0.10))
                        .frame(width: 148, height: 148)
                        .blur(radius: 6)
                    Circle()
                        .strokeBorder(AppTheme.brand.opacity(0.18), lineWidth: 1)
                        .frame(width: 148, height: 148)
                    Image(systemName: page.symbol)
                        .font(.system(size: 54, weight: .semibold))
                        .foregroundStyle(AppTheme.brandGradient)
                }
                .padding(.top, 28)

                VStack(spacing: 10) {
                    Text(page.title)
                        .font(.appDisplay(32))
                        .foregroundStyle(AppTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                    Text(page.subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 28)
                }

                VStack(spacing: 0) {
                    ForEach(Array(page.features.enumerated()), id: \.offset) { index, feature in
                        HStack(spacing: 12) {
                            Image(systemName: feature.0)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AppTheme.brand)
                                .frame(width: 34, height: 34)
                                .background(AppTheme.brand.opacity(0.10), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            Text(feature.1)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(AppTheme.textPrimary)
                            Spacer()
                        }
                        .padding(.vertical, 10)
                        if index < page.features.count - 1 {
                            Rectangle()
                                .fill(AppTheme.stroke)
                                .frame(height: 0.6)
                                .padding(.leading, 46)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .solidCard()
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 16)
        }
    }

    private var footer: some View {
        VStack(spacing: 14) {
            HStack(spacing: 7) {
                ForEach(pages.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == page ? AppTheme.brand : AppTheme.textTertiary.opacity(0.28))
                        .frame(width: index == page ? 20 : 6, height: 6)
                        .animation(AppTheme.quick, value: page)
                }
            }

            Button {
                if page < pages.count - 1 {
                    withAnimation(AppTheme.standard) { page += 1 }
                } else {
                    finish()
                }
            } label: {
                HStack(spacing: 6) {
                    Text(page < pages.count - 1 ? "下一步" : "开始使用")
                    Image(systemName: page < pages.count - 1 ? "arrow.right" : "checkmark")
                        .font(.system(size: 12, weight: .bold))
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppTheme.onBrand)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(AppTheme.brandGradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: AppTheme.brand.opacity(0.35), radius: 18, y: 8)
            }
            .buttonStyle(AppPressStyle(scale: 0.98))
            .padding(.horizontal, 24)
        }
        .padding(.bottom, 22)
    }

    private func finish() {
        onFinish()
    }
}
