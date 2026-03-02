import Foundation

protocol RecordingService {
    func startRecording() throws
    func stopRecording() throws -> URL
    func currentAudioLevel() -> Float
}

protocol TranscriptionService {
    func transcribe(audioURL: URL, settings: AppSettings) async throws -> String
}

protocol CorrectionService {
    func correct(text: String, settings: AppSettings) async throws -> String
}

protocol TextInsertionService {
    func insert(text: String) throws
}

protocol SettingsStore {
    func load() -> AppSettings
    func save(_ settings: AppSettings)
}

protocol ShortcutManager {
    var onToggleRecordingRequested: (() -> Void)? { get set }
    func startMonitoring(shortcut: ShortcutDefinition)
    func stopMonitoring()
}

protocol AppLogger {
    func info(_ message: String, sessionID: String?)
    func error(_ message: String, sessionID: String?)
}

protocol PermissionChecker {
    func hasMicrophonePermission() -> Bool
    func hasAccessibilityPermission() -> Bool
}
