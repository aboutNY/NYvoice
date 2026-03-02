import Foundation
import OSLog

final class OSLogLogger: AppLogger {
    private let logger = Logger(subsystem: "com.nyvoice.app", category: "session")

    func info(_ message: String, sessionID: String?) {
        logger.info("[session=\(sessionID ?? "-")] \(message)")
    }

    func error(_ message: String, sessionID: String?) {
        logger.error("[session=\(sessionID ?? "-")] \(message)")
    }
}
