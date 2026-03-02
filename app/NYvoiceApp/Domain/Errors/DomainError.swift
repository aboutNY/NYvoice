import Foundation

enum DomainError: Error, LocalizedError {
    case permissionDenied(String)
    case recording(String)
    case transcription(String)
    case correction(String)
    case insertion(String)
    case invalidState(String)

    var errorDescription: String? {
        switch self {
        case .permissionDenied(let detail):
            return "Permission denied: \(detail)"
        case .recording(let detail):
            return "Recording failed: \(detail)"
        case .transcription(let detail):
            return "Transcription failed: \(detail)"
        case .correction(let detail):
            return "Correction failed: \(detail)"
        case .insertion(let detail):
            return "Insertion failed: \(detail)"
        case .invalidState(let detail):
            return "Invalid state: \(detail)"
        }
    }
}
