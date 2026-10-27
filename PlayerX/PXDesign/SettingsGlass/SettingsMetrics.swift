import SwiftUI

enum SettingsMetrics {
    static let pageMaxContentWidth: CGFloat = 720
    static let pageTopInset: CGFloat = 18
    static let pageBottomInset: CGFloat = 40
    static let sectionSpacing: CGFloat = 22
    static let sectionHeaderSpacing: CGFloat = 8
    static let sectionHeaderInset: CGFloat = 8
    static let cardCornerRadius: CGFloat = 22
    static let cardContentInset: CGFloat = 16
    static let cardContentVerticalInset: CGFloat = 6
    static let cardRowMinHeight: CGFloat = PXPlatform.isMac ? 30 : 44
    static let rowVerticalInset: CGFloat = PXPlatform.isMac ? 6 : 7
    static let rowLeadingInset: CGFloat = 16
    static let iconColumnWidth: CGFloat = 24
    static let iconGlyphSize: CGFloat = 18
    static let iconLabelSpacing: CGFloat = 12
    static let separatorLeading: CGFloat = 52
    static let cardNoteVerticalPadding: CGFloat = 4
    static let cardTrailingFieldMaxWidth: CGFloat = 300
}
