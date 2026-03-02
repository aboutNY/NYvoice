import AVFoundation
import Foundation

final class AVAudioRecordingService: NSObject, RecordingService {
    private var recorder: AVAudioRecorder?

    func startRecording() throws {
        let url = temporaryRecordingURL()
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: 16_000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]

        recorder = try AVAudioRecorder(url: url, settings: settings)
        guard let recorder else {
            throw DomainError.recording("Failed to initialize recorder")
        }

        recorder.isMeteringEnabled = true
        recorder.prepareToRecord()
        guard recorder.record() else {
            throw DomainError.recording("Failed to start recording")
        }
    }

    func stopRecording() throws -> URL {
        guard let recorder else {
            throw DomainError.recording("No active recording")
        }

        recorder.stop()
        self.recorder = nil
        return recorder.url
    }

    func currentAudioLevel() -> Float {
        guard let recorder else { return 0 }
        recorder.updateMeters()
        let averagePower = recorder.averagePower(forChannel: 0)

        let minDB: Float = -55
        let clampedDB = max(minDB, min(0, averagePower))
        let normalized = (clampedDB - minDB) / abs(minDB)
        let boosted = pow(normalized, 0.55)
        return max(0, min(1, boosted))
    }

    private func temporaryRecordingURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("nyvoice-\(UUID().uuidString)")
            .appendingPathExtension("wav")
    }
}
