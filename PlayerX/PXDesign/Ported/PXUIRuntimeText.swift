import SwiftUI

struct PXUIRuntimeText: View {
    let minutes: Int?

    var body: some View {
        Text(Self.format(minutes))
            .font(PXFont.caption(11))
            .foregroundStyle(PXTheme.textSecondary)
    }

    static func format(_ minutes: Int?) -> String {
        guard let minutes, minutes > 0 else { return "—" }
        if minutes < 60 { return "\(minutes) 分钟" }
        let h = minutes / 60, m = minutes % 60
        return m == 0 ? "\(h) 小时" : "\(h) 小时 \(m) 分"
    }
}
