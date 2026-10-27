import SwiftUI

struct PXWQualityPicker: View {
    let options: [PXPlaybackQualityOption]
    let current: Int?
    var select: (Int) -> Void
    var body: some View {
        Menu {
            ForEach(options.isEmpty ? [.auto] : options) { option in
                Button(option.title) { select(option.value) }
            }
        } label: {
            Text(current.map(PXFormat.quality) ?? "自动").font(PXFont.mono(10))
        }
    }
}
