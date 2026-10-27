import SwiftUI

struct PXDXSeasonPicker: View {
    let seasons: [PXSeasonInfo]
    @Binding var selection: Int
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                ForEach(seasons) { season in
                    PXUIOptionChip(title: season.displayName, isSelected: selection == season.seasonNumber) {
                        selection = season.seasonNumber
                    }
                }
            }
        }
    }
}
