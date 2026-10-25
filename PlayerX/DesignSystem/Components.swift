import SwiftUI
import Foundation

// MARK: - 页面背景

/// 全 App 统一的深色氛围底。比纯黑多一点冷暖层次，所有 Tab 共用。
struct AppBackground: View {
    var body: some View {
        ZStack {
            AppTheme.background
            LinearGradient(
                colors: [Color.primary.opacity(0.025), .clear, Color.primary.opacity(0.015)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
    }
}

/// 用剧集封面做的模糊氛围背景。详情页 / 播放器待机页 / 播放结束页共用。
///
/// 封面走 `CoverLoader`（Go 核心的 cover action，带正确 Referer），不是裸 URL；
/// 拿不到图时退化为纯色渐变，不阻塞页面内容。
struct AmbientCoverBackground: View {
    let drama: Drama
    var intensity: Double = 1
    var showsContent: Bool = true

    @Environment(\.colorScheme) private var colorScheme
    @State private var image: PlatformImage?

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                AppTheme.background
                if let image {
                    Image(platformImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                        .blur(radius: 46)
                        .saturation(colorScheme == .light ? 1.08 : 1.0)
                        .scaleEffect(1.14)
                        .opacity((colorScheme == .light ? 0.46 : 0.58) * intensity)
                }
                LinearGradient(
                    colors: colorScheme == .light
                        ? [
                            Color.white.opacity(0.10),
                            Color.white.opacity(0.48),
                            AppTheme.background
                        ]
                        : [
                            Color.black.opacity(0.06),
                            Color.black.opacity(0.46),
                            AppTheme.background
                        ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                LinearGradient(
                    colors: [Color.primary.opacity(0.03), .clear],
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
        .task(id: drama.id) {
            guard showsContent else { return }
            image = try? await CoverLoader.load(for: drama)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - 材质 / 卡片

struct GlassCardModifier: ViewModifier {
    var radius: CGFloat = AppTheme.cardRadius
    var padding: CGFloat? = nil
    var tint: Color? = nil

    func body(content: Content) -> some View {
        content
            .padding(padding ?? 0)
            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .fill(tint?.opacity(0.16) ?? Color.clear)
                    }
            }
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(AppTheme.stroke, lineWidth: 0.8)
            }
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

struct SolidCardModifier: ViewModifier {
    var radius: CGFloat = AppTheme.cardRadius
    var padding: CGFloat? = nil

    func body(content: Content) -> some View {
        content
            .padding(padding ?? 0)
            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(AppTheme.surfaceMuted)
                    .overlay {
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .fill(AppTheme.cardSheen)
                    }
            }
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(AppTheme.stroke, lineWidth: 0.8)
            }
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

extension View {
    func glassCard(radius: CGFloat = AppTheme.cardRadius, padding: CGFloat? = nil, tint: Color? = nil) -> some View {
        modifier(GlassCardModifier(radius: radius, padding: padding, tint: tint))
    }

    func solidCard(radius: CGFloat = AppTheme.cardRadius, padding: CGFloat? = nil) -> some View {
        modifier(SolidCardModifier(radius: radius, padding: padding))
    }
}

// MARK: - 按钮

/// 按压缩放：iOS 没有 hover，按下时的即时反馈是「这个卡可点」最重要的信号。
struct AppPressStyle: ButtonStyle {
    var scale: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? 0.86 : 1)
            .animation(AppTheme.quick, value: configuration.isPressed)
    }
}

/// 主操作按钮：品牌渐变 + 深色文字，和系统 `.borderedProminent` 区分开。
struct BrandActionButtonStyle: ButtonStyle {
    var compact: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: compact ? 14 : 16, weight: .semibold))
            .foregroundStyle(AppTheme.onBrand)
            .padding(.horizontal, compact ? 16 : 22)
            .frame(height: compact ? 40 : AppTheme.controlHeight)
            .background(AppTheme.brandGradient, in: Capsule())
            .overlay {
                Capsule().strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(0.12), radius: 8, y: 3)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(AppTheme.quick, value: configuration.isPressed)
    }
}

/// 次级操作：玻璃胶囊。
struct SecondaryActionButtonStyle: ButtonStyle {
    var compact: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: compact ? 13 : 15, weight: .semibold))
            .foregroundStyle(AppTheme.textPrimary)
            .padding(.horizontal, compact ? 13 : 18)
            .frame(height: compact ? 36 : 46)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay {
                Capsule().strokeBorder(AppTheme.stroke, lineWidth: 0.8)
            }
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(AppTheme.quick, value: configuration.isPressed)
    }
}

/// 圆形玻璃图标按钮。给详情页的收藏/下载、播放器顶栏用。
struct CircleIconButton: View {
    let systemImage: String
    var accessibilityLabel: String
    var size: CGFloat = 42
    var isActive: Bool = false
    var tint: Color = AppTheme.brand
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size * 0.38, weight: .semibold))
                .foregroundStyle(isActive ? tint : AppTheme.textPrimary)
                .frame(width: size, height: size)
                .background(.ultraThinMaterial, in: Circle())
                .overlay {
                    Circle().strokeBorder(isActive ? tint.opacity(0.6) : AppTheme.stroke, lineWidth: 0.9)
                }
        }
        .buttonStyle(AppPressStyle())
        .accessibilityLabel(accessibilityLabel)
    }
}

// MARK: - 品牌标识

/// 用 SwiftUI 重绘的 App 图标（渐变方块 + 轨道 + 播放三角），避免从 Assets 取不到 AppIcon。
struct AppMark: View {
    var size: CGFloat = 44
    var showsGlow: Bool = true

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0x1A1D2A), Color(hex: 0x06070B)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            RadialGradient(
                colors: [AppTheme.brandWarm.opacity(0.24), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: size * 0.9
            )
            .clipShape(RoundedRectangle(cornerRadius: size * 0.24, style: .continuous))

            Image(systemName: "play.fill")
                .font(.system(size: size * 0.38, weight: .black))
                .foregroundStyle(AppTheme.logoGradient)
                .offset(x: size * 0.025)
                .shadow(color: AppTheme.brandWarm.opacity(0.35), radius: size * 0.16, y: size * 0.04)
        }
        .frame(width: size, height: size)
        .overlay {
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 0.8)
        }
        .shadow(color: showsGlow ? AppTheme.brandWarm.opacity(0.28) : .clear, radius: size * 0.42, y: size * 0.16)
        .accessibilityHidden(true)
    }
}

// MARK: - 标题 / 标签

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 8)
            if let actionTitle, let action {
                Button(action: action) {
                    HStack(spacing: 3) {
                        Text(actionTitle)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// 小标签（类型、清晰度、来源、集数）。
struct MetaPill: View {
    let text: String
    var systemImage: String? = nil
    var tint: Color = AppTheme.textSecondary
    var filled: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 9, weight: .bold))
            }
            Text(text)
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(1)
        }
        .foregroundStyle(filled ? AppTheme.onBrand : tint)
        .padding(.horizontal, 8)
        .frame(height: 22)
        .background {
            Capsule()
                .fill(filled ? tint.opacity(0.85) : AppTheme.surface)
        }
        .overlay {
            Capsule().strokeBorder(filled ? Color.clear : AppTheme.stroke, lineWidth: 0.7)
        }
    }
}

/// 站源标记：一个很小的圆点 + 站名，用站源自己的主题色。
struct SourceBadge: View {
    let sourceId: String
    var name: String

    private var style: SourceVisualStyle { SourceVisualStyle.style(for: sourceId) }

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(style.gradient)
                .frame(width: 7, height: 7)
            Text(name)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(1)
        }
    }
}

struct CountBadge: View {
    let count: Int

    var body: some View {
        Text("\(count)")
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(AppTheme.textSecondary)
            .padding(.horizontal, 7)
            .frame(minWidth: 22, minHeight: 20)
            .background(Capsule().fill(AppTheme.surface))
            .overlay(Capsule().strokeBorder(AppTheme.stroke, lineWidth: 0.6))
    }
}

// MARK: - 进度

struct ProgressTrack: View {
    let progress: Double
    var height: CGFloat = 4
    var tint: LinearGradient = AppTheme.brandGradient
    var track: Color = Color.primary.opacity(0.12)

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule()
                    .fill(tint)
                    .frame(width: CGFloat(max(0, min(1, progress))) * proxy.size.width)
            }
        }
        .frame(height: height)
        .clipShape(Capsule())
        .accessibilityValue("\(Int(min(max(progress, 0), 1) * 100))%")
    }
}

// MARK: - 空态 / 骨架

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    var message: String? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.surface)
                    .frame(width: 74, height: 74)
                Image(systemName: systemImage)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Text(title)
                .font(.appSection(17))
                .foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.center)
            if let message {
                Text(message)
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.textTertiary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.horizontal, 28)
            }
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(SecondaryActionButtonStyle(compact: true))
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

struct SkeletonBlock: View {
    var radius: CGFloat = 12
    @State private var bright = false

    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(Color.white.opacity(bright ? 0.13 : 0.07))
            .appMotion(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: bright)
            .onAppear { bright = true }
    }
}

struct SkeletonPosterCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SkeletonBlock(radius: AppTheme.posterRadius)
                .aspectRatio(2.0 / 3.0, contentMode: .fit)
            SkeletonBlock(radius: 4)
                .frame(height: 11)
            SkeletonBlock(radius: 4)
                .frame(width: 52, height: 9)
        }
    }
}

// MARK: - 格式化

enum AppFormat {
    static func bytes(_ value: Int64) -> String {
        guard value > 0 else { return "0 MB" }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        formatter.isAdaptive = true
        return formatter.string(fromByteCount: value)
    }

    /// 秒 -> `mm:ss` / `h:mm:ss`。
    static func time(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "00:00" }
        let total = Int(seconds.rounded(.down))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%02d:%02d", minutes, secs)
    }

    /// 秒 -> 「还剩 1 小时 12 分」这类可读文案。
    static func remaining(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds > 0 else { return "已看完" }
        let total = Int(seconds)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if hours > 0 {
            return "还剩 \(hours) 小时 \(minutes) 分"
        }
        if minutes > 0 {
            return "还剩 \(minutes) 分钟"
        }
        return "还剩 \(total) 秒"
    }

    static func heat(_ raw: String?) -> String? {
        guard let raw, !raw.isEmpty else { return nil }
        if let value = Double(raw) {
            if value >= 10_000 {
                return String(format: "%.1f 万", value / 10_000)
            }
            return String(format: "%.0f", value)
        }
        return raw
    }
}

// MARK: - 站源配色

/// 站源没有图片资产，用固定的双色渐变 + SF Symbol 做识别。颜色不写进 Core 层，
/// 只属于 UI，避免以后新增站源时污染数据模型。
struct SourceVisualStyle {
    let gradient: LinearGradient
    let symbol: String
    let tagline: String

    static func style(for sourceId: String) -> SourceVisualStyle {
        switch sourceId {
        case "hongguo":
            return .init(
                gradient: LinearGradient(colors: [Color(hex: 0xFF7A18), Color(hex: 0xFF2D55)], startPoint: .topLeading, endPoint: .bottomTrailing),
                symbol: "flame.fill",
                tagline: "热播短剧 · 每日更新"
            )
        case "hanxiaoquan":
            return .init(
                gradient: LinearGradient(colors: [Color(hex: 0x5B8CFF), Color(hex: 0x8E5BFF)], startPoint: .topLeading, endPoint: .bottomTrailing),
                symbol: "moon.stars.fill",
                tagline: "韩剧 · 高甜合集"
            )
        case "guipian":
            return .init(
                gradient: LinearGradient(colors: [Color(hex: 0x4B5563), Color(hex: 0x111827)], startPoint: .topLeading, endPoint: .bottomTrailing),
                symbol: "theatermasks.fill",
                tagline: "惊悚 · 悬疑 · 午夜场"
            )
        case "sorani":
            return .init(
                gradient: LinearGradient(colors: [Color(hex: 0x22D3EE), Color(hex: 0x2563EB)], startPoint: .topLeading, endPoint: .bottomTrailing),
                symbol: "sparkles.tv.fill",
                tagline: "动漫 · 清新治愈"
            )
        case "huangdou":
            return .init(
                gradient: LinearGradient(colors: [Color(hex: 0xFACC15), Color(hex: 0xF97316)], startPoint: .topLeading, endPoint: .bottomTrailing),
                symbol: "circle.grid.2x2.fill",
                tagline: "黄豆精选"
            )
        case "huangju":
            return .init(
                gradient: LinearGradient(colors: [Color(hex: 0xF472B6), Color(hex: 0xBE123C)], startPoint: .topLeading, endPoint: .bottomTrailing),
                symbol: "sparkle.tv.fill",
                tagline: "剧果剧场"
            )
        case "yeguo":
            return .init(
                gradient: LinearGradient(colors: [Color(hex: 0x34D399), Color(hex: 0x047857)], startPoint: .topLeading, endPoint: .bottomTrailing),
                symbol: "leaf.fill",
                tagline: "野果新剧"
            )
        case "dsd":
            return .init(
                gradient: LinearGradient(colors: [Color(hex: 0xA78BFA), Color(hex: 0x6D28D9)], startPoint: .topLeading, endPoint: .bottomTrailing),
                symbol: "crown.fill",
                tagline: "帝果独播"
            )
        case "huangguo-video":
            return .init(
                gradient: LinearGradient(colors: [Color(hex: 0xFB923C), Color(hex: 0xC2410C)], startPoint: .topLeading, endPoint: .bottomTrailing),
                symbol: "play.rectangle.fill",
                tagline: "黄果视频"
            )
        case "huangguoai":
            return .init(
                gradient: LinearGradient(colors: [Color(hex: 0x2DD4BF), Color(hex: 0x0F766E)], startPoint: .topLeading, endPoint: .bottomTrailing),
                symbol: "wand.and.stars",
                tagline: "AI 生成剧场"
            )
        default:
            return .init(
                gradient: LinearGradient(colors: [Color(hex: 0x64748B), Color(hex: 0x334155)], startPoint: .topLeading, endPoint: .bottomTrailing),
                symbol: "play.square.stack.fill",
                tagline: "黄果旧版"
            )
        }
    }
}
