import SwiftUI

struct PXSourceBrowseView: View {
    let descriptor: SourceDescriptor

    var body: some View {
        PXBrowseView(section: .library, initialSource: descriptor.id)
    }
}
