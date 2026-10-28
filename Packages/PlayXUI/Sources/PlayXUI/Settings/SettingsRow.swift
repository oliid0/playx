import SwiftUI

public enum SettingsRowIconSource: Hashable {
    case symbol(String)
    case brand(name: String, aspect: CGFloat)
}

public struct SettingsRowIcon: View {
    let source: SettingsRowIconSource

    public init(_ source: SettingsRowIconSource) { self.source = source }
    public init(systemImage: String) { self.source = .symbol(systemImage) }

    public var body: some View {
        Group {
            switch source {
            case .symbol(let name):
                Image(systemName: name)
                    .font(.system(size: SettingsMetrics.iconGlyphSize))
                    .foregroundStyle(.primary)
            case .brand(let name, _):
                Image(name)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.primary)
            }
        }
        .frame(width: SettingsMetrics.iconColumnWidth, height: SettingsMetrics.iconGlyphSize)
        .accessibilityHidden(true)
    }
}

public struct SettingsRowValue: View {
    let text: String
    public var body: some View {
        Text(text)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .truncationMode(.middle)
    }
}

public struct SettingsRowChevron: View {
    public var body: some View {
        Image(systemName: "chevron.right")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.tertiary)
            .accessibilityHidden(true)
    }
}

/// 与 OcPlayer `SettingsNavRow` 同一行身；抽出纯内容供 NavigationLink 复用。
public struct SettingsNavRowContent: View {
    let title: String
    let icon: SettingsRowIconSource
    var value: String?

    public var body: some View {
        HStack(spacing: SettingsMetrics.iconLabelSpacing) {
            SettingsRowIcon(icon)
            Text(title)
            Spacer(minLength: 8)
            if let value, !value.isEmpty { SettingsRowValue(text: value) }
            SettingsRowChevron()
        }
        .settingsRow()
        .contentShape(.rect)
    }
}

public struct SettingsNavRow: View {
    let title: String
    let icon: SettingsRowIconSource
    var value: String?
    var action: () -> Void

    public init(title: String, icon: SettingsRowIconSource, value: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.value = value
        self.action = action
    }

    public init(title: String, systemImage: String, value: String? = nil, action: @escaping () -> Void) {
        self.init(title: title, icon: .symbol(systemImage), value: value, action: action)
    }

    public var body: some View {
        Button(action: action) {
            SettingsNavRowContent(title: title, icon: icon, value: value)
        }
        .buttonStyle(.plain)
        .accessibilityValue(value ?? "")
    }
}

/// NavigationLink 版本：用于 SwiftUI 栈里保持原生 push/返回。
public struct SettingsNavLink<Destination: View>: View {
    let title: String
    let icon: SettingsRowIconSource
    var value: String?
    let destination: Destination

    public init(title: String, icon: SettingsRowIconSource, value: String? = nil, @ViewBuilder destination: () -> Destination) {
        self.title = title
        self.icon = icon
        self.value = value
        self.destination = destination()
    }

    public init(title: String, systemImage: String, value: String? = nil, @ViewBuilder destination: () -> Destination) {
        self.init(title: title, icon: .symbol(systemImage), value: value, destination: destination)
    }

    public var body: some View {
        NavigationLink(destination: destination) {
            SettingsNavRowContent(title: title, icon: icon, value: value)
        }
        .buttonStyle(.plain)
    }
}

public struct SettingsNote: View {
    let text: String
    public init(_ text: String) { self.text = text }

    public var body: some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.primary.opacity(0.82))
            .fixedSize(horizontal: false, vertical: true)
            .padding(.leading, SettingsMetrics.separatorLeading)
            .settingsCardCompact()
    }
}
