import SwiftUI

struct PXUIGradientDivider: View {
    var body: some View {
        LinearGradient(colors: [.clear, PXTheme.strokeStrong, .clear], startPoint: .leading, endPoint: .trailing)
            .frame(height: 1)
    }
}
