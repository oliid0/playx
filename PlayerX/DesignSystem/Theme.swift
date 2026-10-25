import SwiftUI

// MARK: - 颜色 / 尺寸 / 动效
//
// 整个 App 只有这一套视觉 token。颜色取自 App 图标（橙 -> 玫红），在深色底上做
// 「影院 + 编辑推荐」的观感：大面积深色、暖色只用于强调，不用大面积纯红。
// 所有页面统一走后景（AppBackground / AmbientCoverBackground）+ 玻璃卡 + 22pt 横向留白，
// 避免每个 Feature 各写一套 spacing / cornerRadius。

enum AppTheme {
    // 底色：跟随系统。OcPlayer 的视觉是「系统底 + 模糊海洋 + 中性玻璃」，
    // 不再用固定深色/橙色。播放器内部仍然强制深色（视频场景需要）。
    #if os(iOS)
    static let background = Color(uiColor: .systemBackground)
    static let backgroundLift = Color(uiColor: .secondarySystemBackground)
    #elseif os(macOS)
    static let background = Color(nsColor: .windowBackgroundColor)
    static let backgroundLift = Color(nsColor: .underPageBackgroundColor)
    #else
    static let background = Color.white
    static let backgroundLift = Color.gray.opacity(0.12)
    #endif

    static let surface = Color.primary.opacity(0.055)
    static let surfaceStrong = Color.primary.opacity(0.085)
    static let surfaceMuted = Color.primary.opacity(0.035)
    static let stroke = Color.primary.opacity(0.08)
    static let strokeStrong = Color.primary.opacity(0.15)

    // 强调色：OcPlayer 是中性强调（选中/主行动靠明暗，不靠色相）。
    // 橙色只保留给 AppMark / 图标本身，不参与页面 UI。
    static let brand = Color.primary
    #if os(iOS)
    static let onBrand = Color(uiColor: .systemBackground)
    #elseif os(macOS)
    static let onBrand = Color(nsColor: .windowBackgroundColor)
    #else
    static let onBrand = Color.white
    #endif
    static let brandWarm = Color(red: 1.00, green: 0.55, blue: 0.08)
    static let brandSoft = Color.secondary
    static let lilac = Color.blue
    static let mint = Color.green
    static let warning = Color.orange
    static let danger = Color.red

    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let textTertiary = Color.secondary.opacity(0.72)

    // 尺寸：OcPlayer 的 52 / 22 横向留白、10pt 卡圆角、178pt 海报。
    static var contentPadding: CGFloat {
        #if os(macOS)
        52
        #else
        Platform.isPad ? 44 : 22
        #endif
    }
    static let compactPadding: CGFloat = 22
    static let sectionSpacing: CGFloat = 18
    static let railSpacing: CGFloat = 22
    static let railTopInset: CGFloat = 18
    static let cardRadius: CGFloat = 16
    static let posterRadius: CGFloat = 10
    static let smallRadius: CGFloat = 8
    static let controlHeight: CGFloat = 48
    static let tabBarHeight: CGFloat = 54
    static let posterWidth: CGFloat = 178
    static let compactPosterWidth: CGFloat = 120
    static let stillWidth: CGFloat = 328
    static let compactStillWidth: CGFloat = 240

    // 渐变
    static let brandGradient = LinearGradient(
        colors: [Color.primary, Color.primary.opacity(0.86)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let logoGradient = LinearGradient(
        colors: [Color(hex: 0xFFB000), Color(hex: 0xFF2D55)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let warmGlow = LinearGradient(
        colors: [Color.primary.opacity(0.10), Color.primary.opacity(0.02)],
        startPoint: .leading,
        endPoint: .trailing
    )
    static let cardSheen = LinearGradient(
        colors: [Color.primary.opacity(0.055), Color.primary.opacity(0.01)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let pageGradient = LinearGradient(
        colors: [background, background],
        startPoint: .top,
        endPoint: .bottom
    )

    // 动效（OcPlayer 的节奏）
    static let quick = Animation.easeOut(duration: 0.12)
    static let standard = Animation.easeInOut(duration: 0.20)
    static let gentleSpring = Animation.spring(response: 0.34, dampingFraction: 0.84, blendDuration: 0.12)
    static let hero = Animation.easeInOut(duration: 0.5)
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

extension Font {
    /// 页面大标题：圆体 + 黑重，和播放三角图标有一点轻松感。
    static func appDisplay(_ size: CGFloat = 32) -> Font {
        .system(size: size, weight: .bold)
    }

    static func appTitle(_ size: CGFloat = 22) -> Font {
        .system(size: size, weight: .semibold)
    }

    static func appSection(_ size: CGFloat = 18) -> Font {
        .system(size: size, weight: .bold)
    }

    /// 数字（时间、集数、下载进度）统一用等宽，播放时不会左右跳。
    static func appMono(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

// MARK: - 通用动画封装
//
// 只允许走这里，内部自动尊重「减弱动态效果」。避免每个页面重复写
// withAnimation(.easeInOut) 导致节奏不一致。

private struct AppMotionModifier<V: Equatable>: ViewModifier {
    let animation: Animation
    let value: V
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? nil : animation, value: value)
    }
}

extension View {
    func appMotion<V: Equatable>(_ animation: Animation, value: V) -> some View {
        modifier(AppMotionModifier(animation: animation, value: value))
    }

    /// 页面统一背景，放在 ScrollView 后面。
    func appPageBackground() -> some View {
        background(AppBackground())
    }
}
