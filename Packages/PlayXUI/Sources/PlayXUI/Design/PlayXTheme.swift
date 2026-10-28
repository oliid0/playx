import SwiftUI

public enum PlayXTheme {
    public static let background = Color(red: 0.035, green: 0.039, blue: 0.050)
    public static let textPrimary = Color.white.opacity(0.94)
    public static let textSecondary = Color.white.opacity(0.64)
    public static let textTertiary = Color.white.opacity(0.40)
    public static let accent = Color(red: 0.965, green: 0.714, blue: 0.365)
    public static let stroke = Color.white.opacity(0.10)
    public static let surface = Color.white.opacity(0.055)
    public static let surfaceStrong = Color.white.opacity(0.095)
    public static let accentGradient = LinearGradient(
        colors: [accent, Color(red: 0.925, green: 0.353, blue: 0.455)],
        startPoint: .leading, endPoint: .trailing
    )
}

public extension Font {
    static func ocTitle(_ size: CGFloat) -> Font { .system(size: size, weight: .bold, design: .rounded) }
    static func ocBody(_ size: CGFloat) -> Font { .system(size: size, weight: .regular) }
    static func ocCaption(_ size: CGFloat) -> Font { .system(size: size, weight: .medium) }
}
