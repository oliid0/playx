import SwiftUI

struct PXHomeHeader: View {
    var onSearch: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            HStack(spacing: 10) {
                PXLogoMark(size: 38)
                VStack(alignment: .leading, spacing: 1) {
                    Text(greeting)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(PXTheme.textTertiary)
                    Text("PlayerX")
                        .font(PXFont.display(24))
                        .foregroundStyle(PXTheme.textPrimary)
                }
            }
            Spacer()
            PXToolbarIcon(symbol: "magnifyingglass", action: onSearch)
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<11: return "早上好，今天看点什么"
        case 11..<14: return "午间放映厅"
        case 14..<19: return "下午好"
        default: return "今晚看点什么"
        }
    }
}
