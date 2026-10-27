import SwiftUI

struct PXUIPosterGrid<Item: Identifiable, Content: View>: View {
    let items: [Item]
    var columns: Int = 5
    let content: (Item) -> Content

    init(items: [Item], columns: Int = 5, @ViewBuilder content: @escaping (Item) -> Content) {
        self.items = items
        self.columns = columns
        self.content = content
    }

    private var grid: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 14, alignment: .top), count: max(columns, 1))
    }

    var body: some View {
        LazyVGrid(columns: grid, spacing: 22) {
            ForEach(items) { item in content(item) }
        }
    }
}
