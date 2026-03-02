import Foundation

final class WhisperProcessTranscriptionService: TranscriptionService {
    func transcribe(audioURL: URL, settings: AppSettings) async throws -> String {
        guard FileManager.default.isExecutableFile(atPath: settings.whisperBinaryPath) else {
            throw DomainError.transcription("[CONFIG] Whisper binary is missing or not executable: \(settings.whisperBinaryPath)")
        }

        guard !settings.whisperModelPath.isEmpty else {
            throw DomainError.transcription("[CONFIG] Whisper model path is not configured")
        }

        guard FileManager.default.fileExists(atPath: settings.whisperModelPath) else {
            throw DomainError.transcription("[CONFIG] Whisper model file not found: \(settings.whisperModelPath)")
        }

        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: settings.whisperBinaryPath)
            process.arguments = [
                "-m", settings.whisperModelPath,
                "-f", audioURL.path,
                "-l", "ja",
                "-otxt",
                "-of", outputBasePath(for: audioURL)
            ]

            let stderrPipe = Pipe()
            process.standardError = stderrPipe

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: DomainError.transcription("[LAUNCH] Failed to run whisper: \(error.localizedDescription)"))
                return
            }

            process.terminationHandler = { process in
                if process.terminationStatus != 0 {
                    let stderr = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
                        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    continuation.resume(throwing: DomainError.transcription(
                        "[EXIT] whisper exited with code \(process.terminationStatus) stderr=\(stderr)"
                    ))
                    return
                }

                let txtURL = URL(fileURLWithPath: self.outputBasePath(for: audioURL) + ".txt")
                guard let text = try? String(contentsOf: txtURL, encoding: .utf8) else {
                    continuation.resume(throwing: DomainError.transcription("[OUTPUT] Failed to read whisper output text file"))
                    return
                }

                let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !cleaned.isEmpty else {
                    continuation.resume(throwing: DomainError.transcription("[OUTPUT] Whisper returned empty transcript"))
                    return
                }

                continuation.resume(returning: cleaned)
            }
        }
    }

    private func outputBasePath(for audioURL: URL) -> String {
        audioURL.deletingPathExtension().path
    }
}
