import SwiftUI

#if os(macOS)
import AppKit
#endif

/// PlayerX 顶栏的独立 UI 模块版本。App 只传状态与回调，不再在 App 内维护第二套
/// 顶栏实现。
public struct PXShellSection: Identifiable, Hashable, Sendable {
    public enum Icon: Hashable, Sendable {
        case symbol(String)
        case brand(String)
    }
    public let id: String
    public let title: String
    public let icon: Icon

    public init(id: String, title: String, icon: Icon) {
        self.id = id
        self.title = title
        self.icon = icon
    }
}

public struct PXShellChrome: View {
    public var sections: [PXShellSection]
    public var selectedID: String
    public var title: String
    public var subtitle: String
    public var canGoBack: Bool
    public var shareURL: URL?
    public var onSelect: (String) -> Void
    public var onBack: () -> Void
    public var onSearch: () -> Void

    @State private var hovering: String?

    public init(
        sections: [PXShellSection],
        selectedID: String,
        title: String,
        subtitle: String,
        canGoBack: Bool,
        shareURL: URL?,
        onSelect: @escaping (String) -> Void,
        onBack: @escaping () -> Void,
        onSearch: @escaping () -> Void
    ) {
        self.sections = sections
        self.selectedID = selectedID
        self.title = title
        self.subtitle = subtitle
        self.canGoBack = canGoBack
        self.shareURL = shareURL
        self.onSelect = onSelect
        self.onBack = onBack
        self.onSearch = onSearch
    }

    public var body: some View {
        HStack(spacing: 12) {
            if canGoBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .bold))
                        .frame(width: 30, height: 30)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(PlayXTheme.textPrimary)
            }

            HStack(spacing: 9) {
                brandMark
                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .kerning(0.6)
                        .foregroundStyle(PlayXTheme.textPrimary)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(PlayXTheme.textTertiary)
                        .lineLimit(1)
                }
            }
            .frame(minWidth: 150, alignment: .leading)

            sectionGroup

            Spacer(minLength: 12)

            #if !os(tvOS)
            if let shareURL {
                ShareLink(item: shareURL) {
                    Image(systemName: "square.and.arrow.up")
                }
                .buttonStyle(iconStyle)
                .accessibilityLabel("分享")
            }
            #endif

            Button(action: onSearch) {
                Image(systemName: "magnifyingglass")
            }
            .buttonStyle(iconStyle)
            .foregroundStyle(selectedID == "search" ? PlayXTheme.accent : PlayXTheme.textPrimary)
            .accessibilityLabel("搜索全部媒体库")
        }
        .padding(.leading, 88)
        .padding(.trailing, 18)
        .padding(.top, 8)
        .padding(.bottom, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(dragBackground)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Rectangle().fill(PlayXTheme.stroke).frame(height: 1)
        }
    }

    private var brandMark: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(PlayXTheme.accentGradient)
                .frame(width: 28, height: 28)
            Image(systemName: "play.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(PlayXTheme.background)
        }
    }

    private var sectionGroup: some View {
        HStack(spacing: 3) {
            ForEach(sections) { section in
                Button {
                    guard section.id != selectedID else { return }
                    onSelect(section.id)
                } label: {
                    HStack(spacing: 6) {
                        icon(section)
                        Text(section.title).font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(section.id == selectedID ? PlayXTheme.textPrimary : PlayXTheme.textSecondary)
                    .padding(.horizontal, 12)
                    .frame(height: 31)
                    .background(section.id == selectedID ? PlayXTheme.surfaceStrong : .clear, in: Capsule())
                }
                .buttonStyle(.plain)
                #if os(macOS)
                .onHover { hovering = $0 ? section.id : nil }
                #endif
            }
        }
        .padding(3)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(PlayXTheme.stroke, lineWidth: 0.7))
        .fixedSize()
    }

    @ViewBuilder
    private func icon(_ section: PXShellSection) -> some View {
        switch section.icon {
        case .symbol(let name):
            Image(systemName: name).font(.system(size: 11, weight: .semibold))
        case .brand(let name):
            Image(name).renderingMode(.template).resizable().scaledToFit().frame(width: 14, height: 13)
        }
    }

    private var iconStyle: PXIconButtonStyle { PXIconButtonStyle(size: 32) }

    @ViewBuilder
    private var dragBackground: some View {
        #if os(macOS)
        PXWindowDragArea()
        #else
        Color.clear
        #endif
    }
}

private struct PXIconButtonStyle: ButtonStyle {
    var size: CGFloat
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(PlayXTheme.textPrimary)
            .frame(width: size, height: size)
            .background(.ultraThinMaterial, in: Circle())
            .overlay(Circle().strokeBorder(PlayXTheme.stroke, lineWidth: 0.7))
            .opacity(configuration.isPressed ? 0.72 : 1)
    }
}

#if os(macOS)
struct PXWindowDragArea: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView { DragView() }
    func updateNSView(_ nsView: NSView, context: Context) {}
    private final class DragView: NSView {
        override func mouseDown(with event: NSEvent) {
            window?.performDrag(with: event)
            super.mouseDown(with: event)
        }
    }
}
#endif
