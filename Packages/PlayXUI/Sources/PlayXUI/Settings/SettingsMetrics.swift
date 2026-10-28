import SwiftUI

public enum SettingsMetrics {
    public static let pageMaxContentWidth: CGFloat = 720
    public static let pageTopInset: CGFloat = 18
    public static let pageBottomInset: CGFloat = 40
    public static let sectionSpacing: CGFloat = 22
    public static let sectionHeaderSpacing: CGFloat = 8
    public static let sectionHeaderInset: CGFloat = 8
    public static let cardCornerRadius: CGFloat = 22
    public static let cardContentInset: CGFloat = 16
    public static let cardContentVerticalInset: CGFloat = 6
    public static let cardRowMinHeight: CGFloat = PXPlatform.isMac ? 30 : 44
    public static let rowVerticalInset: CGFloat = PXPlatform.isMac ? 6 : 7
    public static let rowLeadingInset: CGFloat = 16
    public static let iconColumnWidth: CGFloat = 24
    public static let iconGlyphSize: CGFloat = 18
    public static let iconLabelSpacing: CGFloat = 12
    public static let separatorLeading: CGFloat = 52
    public static let cardNoteVerticalPadding: CGFloat = 4
    public static let cardTrailingFieldMaxWidth: CGFloat = 300
}
