import ApplicationServices
import Foundation

final class StartupDependencyChecker {
    func check(settings: AppSettings, permissionChecker: PermissionChecker) async -> [StartupCheckIssue] {
        var issues: [StartupCheckIssue] = []

        if !permissionChecker.hasMicrophonePermission() {
            issues.append(
                StartupCheckIssue(
                    title: "Microphone permission is not granted",
                    suggestion: "System Settings > Privacy & Security > Microphone で NYvoice を許可してください。"
                )
            )
        }

        let legacyAccessibilityTrusted = permissionChecker.hasAccessibilityPermission()
        let optionsAccessibilityTrusted = isAccessibilityTrustedWithOptions()
        if !legacyAccessibilityTrusted && !optionsAccessibilityTrusted {
            issues.append(
                StartupCheckIssue(
                    title: "Accessibility permission is not granted",
                    suggestion: accessibilitySuggestion(
                        legacyTrusted: legacyAccessibilityTrusted,
                        optionsTrusted: optionsAccessibilityTrusted
                    )
                )
            )
        }

        if !FileManager.default.isExecutableFile(atPath: settings.whisperBinaryPath) {
            issues.append(
                StartupCheckIssue(
                    title: "Whisper binary not found or not executable",
                    suggestion: "設定画面で Whisper binary path を正しい実行ファイルへ設定してください。"
                )
            )
        }

        if settings.whisperModelPath.isEmpty || !FileManager.default.fileExists(atPath: settings.whisperModelPath) {
            issues.append(
                StartupCheckIssue(
                    title: "Whisper model is not configured",
                    suggestion: "設定画面で Whisper model path を設定し、モデルファイルが存在することを確認してください。"
                )
            )
        }

        if await !isOllamaReachable() {
            issues.append(
                StartupCheckIssue(
                    title: "Ollama is not reachable",
                    suggestion: "`ollama serve` を起動し、http://127.0.0.1:11434 へ接続可能なことを確認してください。"
                )
            )
        }

        return issues
    }

    private func isOllamaReachable() async -> Bool {
        guard let url = URL(string: "http://127.0.0.1:11434/api/tags") else {
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 2

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { return false }
            return (200..<300).contains(http.statusCode)
        } catch {
            return false
        }
    }

    private func isAccessibilityTrustedWithOptions() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    private func accessibilitySuggestion(legacyTrusted: Bool, optionsTrusted: Bool) -> String {
        let bundleID = Bundle.main.bundleIdentifier ?? "unknown"
        let executablePath = Bundle.main.executablePath ?? ProcessInfo.processInfo.arguments.first ?? "unknown"
        return """
        System Settings > Privacy & Security > Accessibility で NYvoiceApp を許可してください。
        許可対象は現在実行中の実体です: bundle id=\(bundleID), executable=\(executablePath)
        debug: AXIsProcessTrusted=\(legacyTrusted), AXIsProcessTrustedWithOptions=\(optionsTrusted)
        """
    }
}
