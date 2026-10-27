import SwiftUI

struct PXTVXSeasonPicker: View {
    let seasons: [Int]
    @Binding var selection: Int
    var body: some View {
        HStack(spacing: 8) {
            ForEach(seasons, id: \.self) { season in
                Button("第 \(season) 季") { selection = season }
                    .buttonStyle(.card)
                    .font(PXFont.caption(10))
            }
        }
    }
}
