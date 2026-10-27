import SwiftUI

struct PXDXInfoGrid: View {
    let metadata: PXMediaMetadata
    var body: some View {
        VStack(spacing: 0) {
            if let year = metadata.yearText { PXUIKeyValueRow(key: "年份", value: year); PXUIGradientDivider() }
            if let runtime = metadata.runtimeText { PXUIKeyValueRow(key: "时长", value: runtime); PXUIGradientDivider() }
            if let status = metadata.status { PXUIKeyValueRow(key: "状态", value: status); PXUIGradientDivider() }
            if let lang = metadata.originalLanguage { PXUIKeyValueRow(key: "语言", value: lang); PXUIGradientDivider() }
            PXUIKeyValueRow(key: "TMDB", value: "\(metadata.tmdbID)")
        }
    }
}
