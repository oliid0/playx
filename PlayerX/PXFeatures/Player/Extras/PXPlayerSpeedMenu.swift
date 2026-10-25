import SwiftUI
struct PXPlayerSpeedMenu: View {
    var rates: [Double]
    var current: Double
    var onSelect: (Double) -> Void
    var body: some View {
        Menu {
            ForEach(rates, id: \.self) { rate in
                Button(rate == 1 ? "正常" : String(format: "%.2gx", rate)) { onSelect(rate) }
            }
        } label: {
            Text(String(format: "%.2gx", current))
                .font(PXFont.mono(9))
                .foregroundStyle(.white.opacity(0.72))
        }
    }
}
