import Foundation
import OSLog

enum PXLog {
    private static let logger = Logger(subsystem: "com.oliid0.playerx", category: "PX")

    static func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
    }

    static func debug(_ message: String) {
        logger.debug("\(message, privacy: .public)")
    }

    static func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
    }
}
