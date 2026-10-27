import SwiftUI

enum SettingsRowIconSource: Hashable {
    case symbol(String)
    case brand(name: String, aspect: CGFloat)
}

struct SettingsRowIcon: View {
    let source: SettingsRowIconSource

    init(_ source: SettingsRowIconSource) { self.source = source }
    init(systemImage: String) { self.source = .symbol(systemImage) }

    var body: some View {
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

struct SettingsRowValue: View {
    let text: String
    var body: some View {
        Text(text)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .truncationMode(.middle)
    }
}

struct SettingsRowChevron: View {
    var body: some View {
        Image(systemName: "chevron.right")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.tertiary)
            .accessibilityHidden(true)
    }
}

/// 与 OcPlayer `SettingsNavRow` 同一行身；抽出纯内容供 NavigationLink 复用。
struct SettingsNavRowContent: View {
    let title: String
    let icon: SettingsRowIconSource
    var value: String?

    var body: some View {
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

struct SettingsNavRow: View {
    let title: String
    let icon: SettingsRowIconSource
    var value: String?
    var action: () -> Void

    init(title: String, icon: SettingsRowIconSource, value: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.value = value
        self.action = action
    }

    init(title: String, systemImage: String, value: String? = nil, action: @escaping () -> Void) {
        self.init(title: title, icon: .symbol(systemImage), value: value, action: action)
    }

    var body: some View {
        Button(action: action) {
            SettingsNavRowContent(title: title, icon: icon, value: value)
        }
        .buttonStyle(.plain)
        .accessibilityValue(value ?? "")
    }
}

/// NavigationLink 版本：用于 SwiftUI 栈里保持原生 push/返回。
struct SettingsNavLink<Destination: View>: View {
    let title: String
    let icon: SettingsRowIconSource
    var value: String?
    let destination: Destination

    init(title: String, icon: SettingsRowIconSource, value: String? = nil, @ViewBuilder destination: () -> Destination) {
        self.title = title
        self.icon = icon
        self.value = value
        self.destination = destination()
    }

    init(title: String, systemImage: String, value: String? = nil, @ViewBuilder destination: () -> Destination) {
        self.init(title: title, icon: .symbol(systemImage), value: value, destination: destination)
    }

    var body: some View {
        NavigationLink(destination: destination) {
            SettingsNavRowContent(title: title, icon: icon, value: value)
        }
        .buttonStyle(.plain)
    }
}

struct SettingsNote: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.primary.opacity(0.82))
            .fixedSize(horizontal: false, vertical: true)
            .padding(.leading, SettingsMetrics.separatorLeading)
            .settingsCardCompact()
    }
}
