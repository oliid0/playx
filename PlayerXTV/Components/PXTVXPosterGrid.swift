import SwiftUI

struct PXTVXPosterGrid<Item: Identifiable, Content: View>: View {
    let items: [Item]
    let content: (Item) -> Content
    init(items: [Item], @ViewBuilder content: @escaping (Item) -> Content) {
        self.items = items
        self.content = content
    }
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 30), count: 5)
    var body: some View {
        LazyVGrid(columns: columns, spacing: 36) { ForEach(items) { content($0) } }
    }
}
