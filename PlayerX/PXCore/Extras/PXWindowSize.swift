import Foundation
struct PXWindowSize {
    var width: CGFloat
    var height: CGFloat
    var isCompact: Bool { width < 560 }
    var columns: Int { width > 1200 ? 7 : width > 900 ? 6 : width > 700 ? 5 : width > 430 ? 4 : 3 }
}
