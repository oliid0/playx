import SwiftUI

struct PXTVXSectionScaffold<Content: View>: View {
    let title: String
    let content: Content
    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            PXTVXRailHeader(title: title, subtitle: nil)
            content
        }
    }
}
