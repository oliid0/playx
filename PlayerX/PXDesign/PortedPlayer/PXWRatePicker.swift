import SwiftUI

struct PXWRatePicker: View {
    @Binding var rate: Double
    var body: some View {
        Menu(PXPlaybackRateController.label(rate)) {
            ForEach(PXPlaybackRateController.rates, id: \.self) { value in
                Button(PXPlaybackRateController.label(value)) { rate = value }
            }
        }
        .font(PXFont.mono(10))
    }
}
