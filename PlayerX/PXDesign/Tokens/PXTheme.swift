import SwiftUI

/// PlayerX 的新视觉语言：深色影院底、暖金强调、玻璃层、细描边。
/// 所有页面都只消费这些 token，避免各 Feature 自己调颜色和圆角。
enum PXTheme {
    static let background = Color(red: 0.035, green: 0.039, blue: 0.050)
    static let backgroundLift = Color(red: 0.070, green: 0.075, blue: 0.092)
    static let backgroundDeep = Color(red: 0.014, green: 0.016, blue: 0.022)
    static let surface = Color.white.opacity(0.055)
    static let surfaceStrong = Color.white.opacity(0.095)
    static let surfaceMuted = Color.white.opacity(0.032)
    static let stroke = Color.white.opacity(0.10)
    static let strokeStrong = Color.white.opacity(0.20)
    static let textPrimary = Color.white.opacity(0.94)
    static let textSecondary = Color.white.opacity(0.64)
    static let textTertiary = Color.white.opacity(0.40)
    static let accent = Color(red: 0.965, green: 0.714, blue: 0.365)
    static let accentSoft = Color(red: 0.992, green: 0.846, blue: 0.620)
    static let rose = Color(red: 0.925, green: 0.353, blue: 0.455)
    static let mint = Color(red: 0.424, green: 0.851, blue: 0.639)
    static let sky = Color(red: 0.424, green: 0.702, blue: 0.996)
    static let warning = Color(red: 0.984, green: 0.749, blue: 0.286)
    static let danger = Color(red: 0.949, green: 0.353, blue: 0.353)
    static let rating = Color(red: 0.980, green: 0.783, blue: 0.310)

    static let posterRadius: CGFloat = 12
    static let cardRadius: CGFloat = 18
    static let panelRadius: CGFloat = 24
    static let compactRadius: CGFloat = 9
    static let contentPadding: CGFloat = 22
    static let widePadding: CGFloat = 48
    static let railSpacing: CGFloat = 14
    static let sectionSpacing: CGFloat = 28
    static let posterWidth: CGFloat = 148
    static let landscapeWidth: CGFloat = 286
    static let heroHeight: CGFloat = 430

    static let spring = Animation.spring(response: 0.38, dampingFraction: 0.84)
    static let quick = Animation.easeOut(duration: 0.16)
    static let standard = Animation.easeInOut(duration: 0.24)
    static let heroMotion = Animation.easeInOut(duration: 0.55)

    static let accentGradient = LinearGradient(
        colors: [accent, rose],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let panelGradient = LinearGradient(
        colors: [Color.white.opacity(0.09), Color.white.opacity(0.035)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let backdropFade = LinearGradient(
        stops: [
            .init(color: .black.opacity(0.18), location: 0),
            .init(color: background.opacity(0.44), location: 0.48),
            .init(color: background, location: 1),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static func padding(for width: CGFloat) -> CGFloat {
        width > 900 ? widePadding : contentPadding
    }
}

enum PXFont {
    static func display(_ size: CGFloat) -> Font { .system(size: size, weight: .heavy, design: .rounded) }
    static func title(_ size: CGFloat) -> Font { .system(size: size, weight: .bold, design: .rounded) }
    static func section(_ size: CGFloat = 20) -> Font { .system(size: size, weight: .bold) }
    static func body(_ size: CGFloat = 14) -> Font { .system(size: size, weight: .regular) }
    static func caption(_ size: CGFloat = 12) -> Font { .system(size: size, weight: .medium) }
    static func mono(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}
