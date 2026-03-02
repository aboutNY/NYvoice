import Foundation

@MainActor
final class AppContainer {
    let sessionController: SessionController
    let shortcutManager: ShortcutManager
    private let settingsStore: SettingsStore
    private let startupChecker: StartupDependencyChecker
    private let defaults = UserDefaults.standard
    private let firstRunCheckKey = "nyvoice.firstRunCheckCompleted"

    init() {
        let settingsStore = UserDefaultsSettingsStore()
        let logger = OSLogLogger()
        let shortcutManager = NSEventShortcutManager()

        self.settingsStore = settingsStore
        self.startupChecker = StartupDependencyChecker()
        self.shortcutManager = shortcutManager
        self.sessionController = SessionController(
            recordingService: AVAudioRecordingService(),
            transcriptionService: WhisperProcessTranscriptionService(),
            correctionService: OllamaCorrectionService(),
            insertionService: SystemTextInsertionService(),
            settingsStore: settingsStore,
            logger: logger,
            permissionChecker: DefaultPermissionChecker()
        )

        shortcutManager.onToggleRecordingRequested = { [weak sessionController] in
            Task { @MainActor in
                sessionController?.toggleRecording()
            }
        }
    }

    func start() {
        let settings = settingsStore.load()
        shortcutManager.startMonitoring(shortcut: settings.shortcut)
    }

    func updateSettings(_ settings: AppSettings) {
        settingsStore.save(settings)
        shortcutManager.startMonitoring(shortcut: settings.shortcut)
    }

    func runStartupChecks(force: Bool) async -> [StartupCheckIssue] {
        if !force && defaults.bool(forKey: firstRunCheckKey) {
            return []
        }

        let issues = await startupChecker.check(
            settings: settingsStore.load(),
            permissionChecker: DefaultPermissionChecker()
        )
        defaults.set(true, forKey: firstRunCheckKey)
        return issues
    }
}
