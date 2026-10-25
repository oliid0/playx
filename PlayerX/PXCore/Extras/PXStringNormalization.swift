import Foundation
extension String {
    var pxTrimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
    var pxNonEmpty: String? { pxTrimmed.isEmpty ? nil : pxTrimmed }
    var pxCollapsedWhitespace: String {
        replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression).pxTrimmed
    }
}
