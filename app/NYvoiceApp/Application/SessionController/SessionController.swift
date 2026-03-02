import Foundation

@MainActor
final class SessionController: ObservableObject {
    @Published private(set) var state: SessionState = .idle
    @Published private(set) var statusMessage: String = "Ready"
    @Published private(set) var recordingElapsedSeconds: Int = 0
    @Published private(set) var recordingAudioLevel: Double = 0

    private let silenceThreshold: Double = 0.03
    private let cancelDisplayDurationNanos: UInt64 = 700_000_000
    private(set) var context: SessionContext?
    private let recordingService: RecordingService
    private let transcriptionService: TranscriptionService
    private let correctionService: CorrectionService
    private let insertionService: TextInsertionService
    private let settingsStore: SettingsStore
    private let logger: AppLogger
    private let permissionChecker: PermissionChecker
    private var recordingTimer: Timer?
    private var audioLevelTimer: Timer?
    private var maxRecordingAudioLevel: Double = 0

    init(
        recordingService: RecordingService,
        transcriptionService: TranscriptionService,
        correctionService: CorrectionService,
        insertionService: TextInsertionService,
        settingsStore: SettingsStore,
        logger: AppLogger,
        permissionChecker: PermissionChecker
    ) {
        self.recordingService = recordingService
        self.transcriptionService = transcriptionService
        self.correctionService = correctionService
        self.insertionService = insertionService
        self.settingsStore = settingsStore
        self.logger = logger
        self.permissionChecker = permissionChecker
    }

    func toggleRecording() {
        switch state {
        case .idle:
            startRecording()
        case .recording:
            Task {
                await stopAndProcessRecording()
            }
        default:
            statusMessage = "Processing in progress"
        }
    }

    func updateSettings(_ settings: AppSettings) {
        settingsStore.save(settings)
        statusMessage = "Settings saved"
    }

    func currentSettings() -> AppSettings {
        settingsStore.load()
    }

    private func startRecording() {
        guard permissionChecker.hasMicrophonePermission() else {
            transitionToError(.permissionDenied("Microphone permission is required"))
            return
        }

        context = .new()
        do {
            try recordingService.startRecording()
            state = .recording
            statusMessage = "Recording..."
            startRecordingTimer()
            startAudioLevelTimer()
            logger.info("recording started", sessionID: context?.sessionID)
        } catch {
            transitionToError(.recording(error.localizedDescription))
        }
    }

    func stopAndProcessRecording() async {
        guard state == .recording else {
            transitionToError(.invalidState("stop called when state=\(state.rawValue)"))
            return
        }

        do {
            let levelAtStop = Double(recordingService.currentAudioLevel())
            let observedLevel = max(levelAtStop, maxRecordingAudioLevel)
            let audioURL = try recordingService.stopRecording()
            stopRecordingTimer()
            stopAudioLevelTimer()
            context?.audioFilePath = audioURL.path
            logger.info("recording stopped", sessionID: context?.sessionID)
            defer { cleanupTemporaryArtifacts(for: audioURL) }
            if observedLevel < silenceThreshold {
                logger.info("silence detected; skipping transcription and insertion", sessionID: context?.sessionID)
                await showCancelledThenReturnToIdle(message: "No speech detected. Canceled.")
                return
            }

            state = .transcribing
            statusMessage = "Transcribing..."
            let settings = settingsStore.load()
            logger.info("transcription started", sessionID: context?.sessionID)
            let raw = try await transcriptionService.transcribe(audioURL: audioURL, settings: settings)
            context?.transcriptRaw = raw
            logger.info("transcription finished", sessionID: context?.sessionID)

            let finalText: String
            if settings.correctionEnabled {
                state = .correcting
                statusMessage = "Correcting..."
                do {
                    finalText = try await correctionService.correct(text: raw, settings: settings)
                } catch {
                    logger.error("correction failed; using raw transcript: \(error.localizedDescription)", sessionID: context?.sessionID)
                    finalText = raw
                }
            } else {
                finalText = raw
            }

            context?.transcriptCorrected = finalText
            state = .inserting
            statusMessage = "Inserting..."

            guard permissionChecker.hasAccessibilityPermission() else {
                throw DomainError.permissionDenied("Accessibility permission is required")
            }

            try insertionService.insert(text: finalText)
            logger.info("insertion succeeded", sessionID: context?.sessionID)

            state = .idle
            statusMessage = "Inserted"
        } catch let domainError as DomainError {
            transitionToError(domainError)
        } catch {
            transitionToError(.transcription(error.localizedDescription))
        }
    }

    func cancelRecording() async {
        guard state == .recording else { return }

        do {
            let audioURL = try recordingService.stopRecording()
            stopRecordingTimer()
            stopAudioLevelTimer()
            context?.audioFilePath = audioURL.path
            logger.info("recording canceled", sessionID: context?.sessionID)
            defer { cleanupTemporaryArtifacts(for: audioURL) }
            await showCancelledThenReturnToIdle(message: "Canceled.")
        } catch let domainError as DomainError {
            transitionToError(domainError)
        } catch {
            transitionToError(.recording(error.localizedDescription))
        }
    }

    private func transitionToError(_ error: DomainError) {
        stopRecordingTimer()
        stopAudioLevelTimer()
        context?.lastError = error
        state = .error
        statusMessage = error.localizedDescription
        logger.error(error.localizedDescription, sessionID: context?.sessionID)
        state = .idle
    }

    private func startRecordingTimer() {
        recordingElapsedSeconds = 0
        recordingTimer?.invalidate()
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                guard let startedAt = self.context?.startedAt else { return }
                self.recordingElapsedSeconds = max(0, Int(Date().timeIntervalSince(startedAt)))
            }
        }
    }

    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        recordingElapsedSeconds = 0
    }

    private func startAudioLevelTimer() {
        recordingAudioLevel = 0
        maxRecordingAudioLevel = 0
        audioLevelTimer?.invalidate()
        sampleAudioLevel()
        audioLevelTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.state == .recording else { return }
                self.sampleAudioLevel()
            }
        }
    }

    private func stopAudioLevelTimer() {
        audioLevelTimer?.invalidate()
        audioLevelTimer = nil
        recordingAudioLevel = 0
        maxRecordingAudioLevel = 0
    }

    private func sampleAudioLevel() {
        let level = Double(recordingService.currentAudioLevel())
        recordingAudioLevel = level
        maxRecordingAudioLevel = max(maxRecordingAudioLevel, level)
    }

    private func showCancelledThenReturnToIdle(message: String) async {
        state = .cancelling
        statusMessage = message
        do {
            try await Task.sleep(nanoseconds: cancelDisplayDurationNanos)
        } catch {
            logger.error("cancel display sleep interrupted: \(error.localizedDescription)", sessionID: context?.sessionID)
        }
        state = .idle
        statusMessage = "Ready"
    }

    private func cleanupTemporaryArtifacts(for audioURL: URL) {
        let fm = FileManager.default
        let base = audioURL.deletingPathExtension().path
        let candidates = [
            audioURL.path,
            base + ".txt",
            base + ".json",
            base + ".srt",
            base + ".vtt"
        ]

        for path in candidates where fm.fileExists(atPath: path) {
            do {
                try fm.removeItem(atPath: path)
                logger.info("temporary artifact deleted: \(path)", sessionID: context?.sessionID)
            } catch {
                logger.error("failed to delete temporary artifact: \(path) error=\(error.localizedDescription)", sessionID: context?.sessionID)
            }
        }
    }
}
