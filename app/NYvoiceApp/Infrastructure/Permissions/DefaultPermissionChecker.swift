import AVFoundation
import ApplicationServices
import Foundation

final class DefaultPermissionChecker: PermissionChecker {
    func hasMicrophonePermission() -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            return true
        case .notDetermined:
            let semaphore = DispatchSemaphore(value: 0)
            var granted = false
            AVCaptureDevice.requestAccess(for: .audio) { isGranted in
                granted = isGranted
                semaphore.signal()
            }
            semaphore.wait()
            return granted
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }

    func hasAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
        let trustedWithOptions = AXIsProcessTrustedWithOptions(options)
        return trustedWithOptions || AXIsProcessTrusted()
    }
}
