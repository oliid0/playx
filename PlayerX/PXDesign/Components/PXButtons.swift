import SwiftUI

struct PXPressStyle: ButtonStyle {
    var scale: CGFloat = 0.96
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(PXTheme.quick, value: configuration.isPressed)
    }
}

struct PXPrimaryButtonStyle: ButtonStyle {
    var compact = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: compact ? 13 : 15, weight: .bold))
            .foregroundStyle(Color.black.opacity(0.88))
            .padding(.horizontal, compact ? 14 : 20)
            .frame(height: compact ? 36 : 46)
            .background(PXTheme.accentGradient, in: Capsule())
            .shadow(color: PXTheme.accent.opacity(0.26), radius: 12, y: 5)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.86 : 1)
            .animation(PXTheme.quick, value: configuration.isPressed)
    }
}

struct PXSecondaryButtonStyle: ButtonStyle {
    var compact = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: compact ? 12 : 14, weight: .semibold))
            .foregroundStyle(PXTheme.textPrimary)
            .padding(.horizontal, compact ? 12 : 18)
            .frame(height: compact ? 34 : 44)
            .background(PXTheme.surfaceStrong, in: Capsule())
            .overlay(Capsule().strokeBorder(PXTheme.strokeStrong, lineWidth: 0.8))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(PXTheme.quick, value: configuration.isPressed)
    }
}

struct PXIconButtonStyle: ButtonStyle {
    var size: CGFloat = 40
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: size * 0.38, weight: .semibold))
            .foregroundStyle(PXTheme.textPrimary)
            .frame(width: size, height: size)
            .background(.ultraThinMaterial, in: Circle())
            .overlay(Circle().strokeBorder(PXTheme.stroke, lineWidth: 0.8))
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(PXTheme.quick, value: configuration.isPressed)
    }
}

struct PXToolbarIcon: View {
    var symbol: String
    var badge: String?
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: symbol)
                if let badge {
                    Text(badge)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 4)
                        .frame(height: 13)
                        .background(PXTheme.accent, in: Capsule())
                        .offset(x: 8, y: -7)
                }
            }
        }
        .buttonStyle(PXIconButtonStyle(size: 38))
    }
}
