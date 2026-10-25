import SwiftUI

struct PXSeasonPicker: View {
    var seasons: [PXSeasonInfo]
    @Binding var selection: Int

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                ForEach(seasons) { season in
                    Button {
                        selection = season.seasonNumber
                    } label: {
                        PXChip(
                            title: season.displayName,
                            selected: selection == season.seasonNumber
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
