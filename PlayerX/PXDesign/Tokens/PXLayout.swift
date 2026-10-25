import SwiftUI

struct PXPageWidth<Content: View>: View {
    var maxWidth: CGFloat = 1320
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .frame(maxWidth: maxWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
    }
}

struct PXAdaptiveColumns {
    static func posters(width: CGFloat) -> [GridItem] {
        let count: Int
        switch width {
        case ..<430: count = 3
        case ..<700: count = 4
        case ..<980: count = 5
        case ..<1280: count = 6
        default: count = 7
        }
        return Array(repeating: GridItem(.flexible(), spacing: 12, alignment: .top), count: count)
    }

    static func wide(width: CGFloat) -> [GridItem] {
        let count = width > 1100 ? 3 : (width > 720 ? 2 : 1)
        return Array(repeating: GridItem(.flexible(), spacing: 14, alignment: .top), count: count)
    }
}
