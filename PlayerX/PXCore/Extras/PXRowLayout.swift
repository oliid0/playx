import SwiftUI
struct PXRowLayout<Content: View>: View {
    var title: String
    var subtitle: String?
    @ViewBuilder var content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PXSectionHeader(title: title, subtitle: subtitle)
            ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 12) { content() } }
        }
    }
}
