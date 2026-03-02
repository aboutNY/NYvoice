import Foundation

struct SessionContext {
    var sessionID: String
    var startedAt: Date
    var audioFilePath: String?
    var transcriptRaw: String?
    var transcriptCorrected: String?
    var lastError: DomainError?

    static func new() -> SessionContext {
        SessionContext(sessionID: UUID().uuidString, startedAt: Date())
    }
}
