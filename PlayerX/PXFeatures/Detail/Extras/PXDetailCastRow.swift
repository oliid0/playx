import SwiftUI
struct PXDetailCastRow: View {
    var cast: [PXCastMember]
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(cast) { PXCastCard(member: $0) }
            }
        }
    }
}
