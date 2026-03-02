import Foundation

enum SessionState: String {
    case idle = "Idle"
    case recording = "Recording"
    case cancelling = "Cancelling"
    case transcribing = "Transcribing"
    case correcting = "Correcting"
    case inserting = "Inserting"
    case error = "Error"
}
