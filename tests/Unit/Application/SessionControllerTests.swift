import Foundation
import XCTest
@testable import NYvoiceApp

@MainActor
final class SessionControllerTests: XCTestCase {
    func testStartsRecordingFromIdle() {
        let recording = MockRecordingService()
        let sut = SessionController(
            recordingService: recording,
            transcriptionService: MockTranscriptionService(result: "hello"),
            correctionService: MockCorrectionService(result: "hello"),
            insertionService: MockInsertionService(),
            settingsStore: MockSettingsStore(),
            logger: MockLogger(),
            permissionChecker: MockPermissionChecker()
        )

        sut.toggleRecording()

        XCTAssertEqual(sut.state, .recording)
        XCTAssertTrue(recording.startCalled)
    }

    func testStopProcessesAndReturnsToIdle() async {
        let recording = MockRecordingService()
        let insertion = MockInsertionService()
        let sut = SessionController(
            recordingService: recording,
            transcriptionService: MockTranscriptionService(result: "raw"),
            correctionService: MockCorrectionService(result: "corrected"),
            insertionService: insertion,
            settingsStore: MockSettingsStore(),
            logger: MockLogger(),
            permissionChecker: MockPermissionChecker()
        )

        sut.toggleRecording()
        await sut.stopAndProcessRecording()

        XCTAssertEqual(sut.state, .idle)
        XCTAssertEqual(insertion.insertedText, "corrected")
    }
}

private final class MockRecordingService: RecordingService {
    var startCalled = false
    var level: Float = 0.25

    func startRecording() throws {
        startCalled = true
    }

    func stopRecording() throws -> URL {
        URL(fileURLWithPath: "/tmp/a.wav")
    }

    func currentAudioLevel() -> Float {
        level
    }
}

private final class MockTranscriptionService: TranscriptionService {
    let result: String

    init(result: String) {
        self.result = result
    }

    func transcribe(audioURL: URL, settings: AppSettings) async throws -> String {
        result
    }
}

private final class MockCorrectionService: CorrectionService {
    let result: String

    init(result: String) {
        self.result = result
    }

    func correct(text: String, settings: AppSettings) async throws -> String {
        result
    }
}

private final class MockInsertionService: TextInsertionService {
    var insertedText: String?

    func insert(text: String) throws {
        insertedText = text
    }
}

private final class MockSettingsStore: SettingsStore {
    func load() -> AppSettings { .default }
    func save(_ settings: AppSettings) {}
}

private final class MockLogger: AppLogger {
    func info(_ message: String, sessionID: String?) {}
    func error(_ message: String, sessionID: String?) {}
}

private final class MockPermissionChecker: PermissionChecker {
    func hasMicrophonePermission() -> Bool { true }
    func hasAccessibilityPermission() -> Bool { true }
}
