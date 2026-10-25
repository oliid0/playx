import Foundation
#if os(iOS) || os(tvOS)
import UIKit
#endif
enum PXDeviceInfo {
    static var name: String {
        #if os(tvOS)
        "Apple TV"
        #elseif os(iOS)
        UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
        #elseif os(macOS)
        "Mac"
        #else
        "Apple"
        #endif
    }
    static var system: String {
        #if os(iOS) || os(tvOS)
        "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
        #else
        ProcessInfo.processInfo.operatingSystemVersionString
        #endif
    }
    static var isPad: Bool {
        #if os(iOS)
        UIDevice.current.userInterfaceIdiom == .pad
        #else
        false
        #endif
    }
}
