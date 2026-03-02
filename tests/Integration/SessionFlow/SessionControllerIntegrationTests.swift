import Foundation
import XCTest
@testable import NYvoiceApp

@MainActor
final class SessionControllerIntegrationTests: XCTestCase {
    func testEndToEndSuccessPath() async {
        let audioURL = makeTempAudioFile()
        let recording = StubRecordingService(audioURL: audioURL, audioLevel: 0.3)
        let insertion = StubInsertionService()
        let sut = makeSUT(
            recording: recording,
            transcription: StubTranscriptionService(result: "raw text"),
            correction: StubCorrectionService(result: "corrected text"),
            insertion: insertion,
            permissions: StubPermissionChecker(microphone: true, accessibility: true)
        )

        sut.toggleRecording()
        await sut.stopAndProcessRecording()

        XCTAssertEqual(sut.state, .idle)
        XCTAssertEqual(sut.statusMessage, "Inserted")
        XCTAssertEqual(insertion.insertedText, "corrected text")
        XCTAssertFalse(FileManager.default.fileExists(atPath: audioURL.path))
    }

    func testCorrectionFailureFallsBackToRawTranscript() async {
        let audioURL = makeTempAudioFile()
        let insertion = StubInsertionService()
        let sut = makeSUT(
            recording: StubRecordingService(audioURL: audioURL, audioLevel: 0.3),
            transcription: StubTranscriptionService(result: "raw text"),
            correction: StubCorrectionService(error: DomainError.correction("ollama down")),
            insertion: insertion,
            permissions: StubPermissionChecker(microphone: true, accessibility: true)
        )

        sut.toggleRecording()
        await sut.stopAndProcessRecording()

        XCTAssertEqual(sut.state, .idle)
        XCTAssertEqual(insertion.insertedText, "raw text")
    }

    func testTranscriptionFailureReturnsToIdleWithErrorMessage() async {
        let audioURL = makeTempAudioFile()
        let sut = makeSUT(
            recording: StubRecordingService(audioURL: audioURL, audioLevel: 0.3),
            transcription: StubTranscriptionService(error: DomainError.transcription("whisper failed")),
            correction: StubCorrectionService(result: "unused"),
            insertion: StubInsertionService(),
            permissions: StubPermissionChecker(microphone: true, accessibility: true)
        )

        sut.toggleRecording()
        await sut.stopAndProcessRecording()

        XCTAssertEqual(sut.state, .idle)
        XCTAssertTrue(sut.statusMessage.contains("Transcription failed"))
        XCTAssertFalse(FileManager.default.fileExists(atPath: audioURL.path))
    }

    func testMicrophonePermissionDenied() {
        let sut = makeSUT(
            recording: StubRecordingService(audioURL: makeTempAudioFile(), audioLevel: 0.3),
            transcription: StubTranscriptionService(result: "unused"),
            correction: StubCorrectionService(result: "unused"),
            insertion: StubInsertionService(),
            permissions: StubPermissionChecker(microphone: false, accessibility: true)
        )

        sut.toggleRecording()

        XCTAssertEqual(sut.state, .idle)
        XCTAssertTrue(sut.statusMessage.contains("Permission denied"))
    }

    func testAccessibilityPermissionDenied() async {
        let sut = makeSUT(
            recording: StubRecordingService(audioURL: makeTempAudioFile(), audioLevel: 0.3),
            transcription: StubTranscriptionService(result: "raw"),
            correction: StubCorrectionService(result: "corrected"),
            insertion: StubInsertionService(),
            permissions: StubPermissionChecker(microphone: true, accessibility: false)
        )

        sut.toggleRecording()
        await sut.stopAndProcessRecording()

        XCTAssertEqual(sut.state, .idle)
        XCTAssertTrue(sut.statusMessage.contains("Permission denied"))
    }

    func testInsertionFailureReturnsToIdleWithErrorMessage() async {
        let sut = makeSUT(
            recording: StubRecordingService(audioURL: makeTempAudioFile(), audioLevel: 0.3),
            transcription: StubTranscriptionService(result: "raw"),
            correction: StubCorrectionService(result: "corrected"),
            insertion: StubInsertionService(error: DomainError.insertion("cannot insert")),
            permissions: StubPermissionChecker(microphone: true, accessibility: true)
        )

        sut.toggleRecording()
        await sut.stopAndProcessRecording()

        XCTAssertEqual(sut.state, .idle)
        XCTAssertTrue(sut.statusMessage.contains("Insertion failed"))
    }

    func testSilenceSkipsTranscriptionAndInsertion() async {
        let audioURL = makeTempAudioFile()
        let insertion = StubInsertionService()
        let sut = makeSUT(
            recording: StubRecordingService(audioURL: audioURL, audioLevelSequence: [0, 0]),
            transcription: StubTranscriptionService(result: "hallucinated text"),
            correction: StubCorrectionService(result: "unused"),
            insertion: insertion,
            permissions: StubPermissionChecker(microphone: true, accessibility: true)
        )

        sut.toggleRecording()
        await sut.stopAndProcessRecording()

        XCTAssertEqual(sut.state, .idle)
        XCTAssertEqual(sut.statusMessage, "Ready")
        XCTAssertNil(insertion.insertedText)
    }

    func testSpeechBeforeStopStillInsertsWhenLevelDropsAtStop() async {
        let audioURL = makeTempAudioFile()
        let insertion = StubInsertionService()
        let sut = makeSUT(
            recording: StubRecordingService(audioURL: audioURL, audioLevelSequence: [0.35, 0.0]),
            transcription: StubTranscriptionService(result: "raw text"),
            correction: StubCorrectionService(result: "corrected text"),
            insertion: insertion,
            permissions: StubPermissionChecker(microphone: true, accessibility: true)
        )

        sut.toggleRecording()
        await sut.stopAndProcessRecording()

        XCTAssertEqual(sut.state, .idle)
        XCTAssertEqual(insertion.insertedText, "corrected text")
    }

    func testCancelRecordingSkipsTranscriptionAndInsertion() async {
        let audioURL = makeTempAudioFile()
        let insertion = StubInsertionService()
        let sut = makeSUT(
            recording: StubRecordingService(audioURL: audioURL, audioLevelSequence: [0.35, 0.0]),
            transcription: StubTranscriptionService(result: "should not be used"),
            correction: StubCorrectionService(result: "unused"),
            insertion: insertion,
            permissions: StubPermissionChecker(microphone: true, accessibility: true)
        )

        sut.toggleRecording()
        await sut.cancelRecording()

        XCTAssertEqual(sut.state, .idle)
        XCTAssertEqual(sut.statusMessage, "Ready")
        XCTAssertNil(insertion.insertedText)
    }

    private func makeSUT(
        recording: RecordingService,
        transcription: TranscriptionService,
        correction: CorrectionService,
        insertion: TextInsertionService,
        permissions: PermissionChecker
    ) -> SessionController {
        SessionController(
            recordingService: recording,
            transcriptionService: transcription,
            correctionService: correction,
            insertionService: insertion,
            settingsStore: StubSettingsStore(),
            logger: StubLogger(),
            permissionChecker: permissions
        )
    }

    private func makeTempAudioFile() -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("nyvoice-test-\(UUID().uuidString)")
            .appendingPathExtension("wav")
        try? Data("dummy".utf8).write(to: url)
        return url
    }
}

private final class StubRecordingService: RecordingService {
    let audioURL: URL
    let audioLevel: Float
    private var audioLevelSequence: [Float]
    init(audioURL: URL, audioLevel: Float = 0.3) {
        self.audioURL = audioURL
        self.audioLevel = audioLevel
        self.audioLevelSequence = []
    }

    init(audioURL: URL, audioLevelSequence: [Float]) {
        self.audioURL = audioURL
        self.audioLevel = audioLevelSequence.last ?? 0
        self.audioLevelSequence = audioLevelSequence
    }
    func startRecording() throws {}
    func stopRecording() throws -> URL { audioURL }
    func currentAudioLevel() -> Float {
        if !audioLevelSequence.isEmpty {
            return audioLevelSequence.removeFirst()
        }
        return audioLevel
    }
}

private final class StubTranscriptionService: TranscriptionService {
    let result: String?
    let error: Error?

    init(result: String) {
        self.result = result
        self.error = nil
    }

    init(error: Error) {
        self.result = nil
        self.error = error
    }

    func transcribe(audioURL: URL, settings: AppSettings) async throws -> String {
        if let error { throw error }
        return result ?? ""
    }
}

private final class StubCorrectionService: CorrectionService {
    let result: String?
    let error: Error?

    init(result: String) {
        self.result = result
        self.error = nil
    }

    init(error: Error) {
        self.result = nil
        self.error = error
    }

    func correct(text: String, settings: AppSettings) async throws -> String {
        if let error { throw error }
        return result ?? text
    }
}

private final class StubInsertionService: TextInsertionService {
    var insertedText: String?
    let error: Error?

    init(error: Error? = nil) {
        self.error = error
    }

    func insert(text: String) throws {
        if let error { throw error }
        insertedText = text
    }
}

private final class StubSettingsStore: SettingsStore {
    func load() -> AppSettings { .default }
    func save(_ settings: AppSettings) {}
}

private final class StubPermissionChecker: PermissionChecker {
    let microphone: Bool
    let accessibility: Bool

    init(microphone: Bool, accessibility: Bool) {
        self.microphone = microphone
        self.accessibility = accessibility
    }

    func hasMicrophonePermission() -> Bool { microphone }
    func hasAccessibilityPermission() -> Bool { accessibility }
}

private final class StubLogger: AppLogger {
    func info(_ message: String, sessionID: String?) {}
    func error(_ message: String, sessionID: String?) {}
}
