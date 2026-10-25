import SwiftUI
struct PXTVSummaryText: View {
    var text: String?
    var body: some View {
        Text(text?.isEmpty == false ? text! : "暂无简介")
            .font(.body).foregroundStyle(PXTheme.textSecondary).lineSpacing(5)
            .frame(maxWidth: 1000, alignment: .leading)
    }
}
