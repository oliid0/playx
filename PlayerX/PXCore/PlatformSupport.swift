import Foundation
#if os(iOS) || os(tvOS)
import UIKit
typealias PlatformImage = UIImage
#elseif os(macOS)
import AppKit
typealias PlatformImage = NSImage
#endif

enum Platform {
    static var screenScale: CGFloat {
        #if os(iOS) || os(tvOS)
        UIScreen.main.scale
        #else
        NSScreen.main?.backingScaleFactor ?? 2
        #endif
    }
}
