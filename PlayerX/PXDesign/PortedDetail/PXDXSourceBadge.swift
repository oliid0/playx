import SwiftUI

struct PXDXSourceBadge: View {
    let sourceID: String
    var body: some View {
        PXUIProviderBadge(
            name: SourceRegistry.descriptor(for: sourceID)?.displayName ?? sourceID,
            symbol: "antenna.radiowaves.left.and.right"
        )
    }
}
