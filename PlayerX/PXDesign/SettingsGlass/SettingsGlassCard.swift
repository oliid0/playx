import SwiftUI

// MARK: - OcPlayer B 方案：ScrollView + 液态玻璃卡片流

enum SettingsCardRole: Equatable {
    case row
    case note
    case inline

    var verticalPadding: CGFloat {
        switch self {
        case .row: SettingsMetrics.rowVerticalInset
        case .note: SettingsMetrics.cardNoteVerticalPadding
        case .inline: 0
        }
    }
}

private struct SettingsCardRoleKey: LayoutValueKey {
    static let defaultValue = SettingsCardRole.row
}

extension View {
    func settingsCardCompact() -> some View {
        layoutValue(key: SettingsCardRoleKey.self, value: SettingsCardRole.note)
    }

    func settingsCardInline() -> some View {
        layoutValue(key: SettingsCardRoleKey.self, value: SettingsCardRole.inline)
    }

    func settingsRow() -> some View {
        frame(minHeight: SettingsMetrics.cardRowMinHeight)
    }

    @ViewBuilder
    func settingsToggleStyle() -> some View {
        #if os(macOS)
        toggleStyle(SettingsSwitchToggleStyle())
        #else
        self
        #endif
    }
}

struct SettingsCardRowLayout: Layout {
    private var minHeight: CGFloat { SettingsMetrics.cardRowMinHeight }

    private func naturalSize(_ subview: LayoutSubview, width: CGFloat) -> CGSize {
        subview.sizeThatFits(ProposedViewSize(width: width, height: nil))
    }

    private func contentHeight(_ size: CGSize, role: SettingsCardRole) -> CGFloat {
        role == .row ? max(size.height, minHeight) : size.height
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? subviews.map { $0.sizeThatFits(.unspecified).width }.max() ?? 0
        guard !subviews.isEmpty else { return .zero }
        var height: CGFloat = 0
        for subview in subviews {
            let role = subview[SettingsCardRoleKey.self]
            let content = contentHeight(naturalSize(subview, width: width), role: role)
            height += content + role.verticalPadding * 2
        }
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for subview in subviews {
            let role = subview[SettingsCardRoleKey.self]
            let padding = role.verticalPadding
            let content = contentHeight(naturalSize(subview, width: bounds.width), role: role)
            subview.place(
                at: CGPoint(x: bounds.minX, y: y + padding + content / 2),
                anchor: .leading,
                proposal: ProposedViewSize(width: bounds.width, height: content)
            )
            y += content + padding * 2
        }
    }
}

struct SettingsGlassCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        SettingsCardRowLayout { content }
            .padding(.horizontal, SettingsMetrics.cardContentInset)
            .padding(.vertical, SettingsMetrics.cardContentVerticalInset)
            .frame(maxWidth: .infinity, alignment: .leading)
            .settingsToggleStyle()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: SettingsMetrics.cardCornerRadius, style: .continuous))
            .background(
                RoundedRectangle(cornerRadius: SettingsMetrics.cardCornerRadius, style: .continuous)
                    .fill(PXTheme.panelGradient)
            )
            .overlay {
                RoundedRectangle(cornerRadius: SettingsMetrics.cardCornerRadius, style: .continuous)
                    .strokeBorder(PXTheme.stroke, lineWidth: 0.8)
            }
    }
}

struct SettingsGlassDivider: View {
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.10))
            .frame(height: 1 / max(displayScale, 1))
            .padding(.leading, SettingsMetrics.iconColumnWidth + SettingsMetrics.iconLabelSpacing)
            .settingsCardInline()
    }
}

struct SettingsGlassSection<Content: View, Footer: View>: View {
    private let title: String?
    private let content: Content
    private let footer: Footer

    init(_ title: String? = nil, @ViewBuilder content: () -> Content, @ViewBuilder footer: () -> Footer) {
        self.title = title
        self.content = content()
        self.footer = footer()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SettingsMetrics.sectionHeaderSpacing) {
            if let title, !title.isEmpty {
                Text(title)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, SettingsMetrics.sectionHeaderInset)
            }
            SettingsGlassCard { content }
            footer
                .font(.caption)
                .foregroundStyle(.primary.opacity(0.82))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, SettingsMetrics.sectionHeaderInset)
        }
    }
}

extension SettingsGlassSection where Footer == EmptyView {
    init(_ title: String? = nil, @ViewBuilder content: () -> Content) {
        self.init(title, content: content) { EmptyView() }
    }
}

struct SettingsGlassPage<Content: View>: View {
    private let content: Content
    private let maxContentWidth: CGFloat

    init(maxContentWidth: CGFloat = SettingsMetrics.pageMaxContentWidth, @ViewBuilder content: () -> Content) {
        self.maxContentWidth = maxContentWidth
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SettingsMetrics.sectionSpacing + 8) {
                content
            }
            .padding(.horizontal, 24)
            .padding(.top, SettingsMetrics.pageTopInset)
            .padding(.bottom, SettingsMetrics.pageBottomInset)
            .frame(maxWidth: maxContentWidth, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .scrollBounceBehavior(.basedOnSize)
    }
}

struct SettingsSwitchToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 12) {
            configuration.label
            Spacer(minLength: 8)
            Toggle(isOn: configuration.$isOn) { EmptyView() }
                .labelsHidden()
                .toggleStyle(.switch)
        }
    }
}

struct SettingsRow<Label: View, Trailing: View>: View {
    private let label: Label
    private let trailing: Trailing

    init(@ViewBuilder label: () -> Label, @ViewBuilder trailing: () -> Trailing) {
        self.label = label()
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: 12) {
            label
            Spacer(minLength: 8)
            trailing
        }
    }
}

extension SettingsRow where Label == Text {
    init(_ title: String, @ViewBuilder trailing: () -> Trailing) {
        self.init(label: { Text(title) }, trailing: trailing)
    }
}

struct SettingsPickerRow<Value: Hashable, Content: View>: View {
    private let title: String
    @Binding private var selection: Value
    private let content: Content

    init(_ title: String, selection: Binding<Value>, @ViewBuilder content: () -> Content) {
        self.title = title
        self._selection = selection
        self.content = content()
    }

    var body: some View {
        SettingsRow(title) {
            Picker(title, selection: $selection) { content }
                .labelsHidden()
                .pickerStyle(.menu)
                .fixedSize()
                .layoutPriority(1)
        }
    }
}

struct SettingsTextRow: View {
    private let title: String
    private let prompt: String
    @Binding private var text: String
    private let isSecure: Bool

    init(_ title: String, text: Binding<String>, prompt: String = "", isSecure: Bool = false) {
        self.title = title
        self._text = text
        self.prompt = prompt
        self.isSecure = isSecure
    }

    var body: some View {
        SettingsRow(title) {
            field
                .textFieldStyle(.plain)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: SettingsMetrics.cardTrailingFieldMaxWidth, alignment: .trailing)
        }
    }

    @ViewBuilder
    private var field: some View {
        if isSecure { SecureField(prompt, text: $text) }
        else { TextField(prompt, text: $text) }
    }
}

struct SettingsActionRow: View {
    private let title: String
    private let icon: String?
    private let role: ButtonRole?
    private let action: () -> Void

    init(_ title: String, systemImage: String? = nil, role: ButtonRole? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = systemImage
        self.role = role
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: SettingsMetrics.iconLabelSpacing) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: SettingsMetrics.iconGlyphSize, weight: .regular))
                        .frame(width: SettingsMetrics.iconColumnWidth, alignment: .center)
                }
                Text(title)
                Spacer(minLength: 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .foregroundStyle(role == .destructive ? AnyShapeStyle(Color.red) : AnyShapeStyle(.primary))
    }
}
