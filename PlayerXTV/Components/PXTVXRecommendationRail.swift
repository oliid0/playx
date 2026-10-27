import SwiftUI

struct PXTVXRecommendationRail<Item: Identifiable, Content: View>: View {
    let items: [Item]
    let content: (Item) -> Content
    init(items: [Item], @ViewBuilder content: @escaping (Item) -> Content) {
        self.items = items
        self.content = content
    }
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 28) { ForEach(items) { content($0) } }
        }
    }
}
