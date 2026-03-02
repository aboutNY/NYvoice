import AppKit
import CoreGraphics
import Foundation

final class NSEventShortcutManager: ShortcutManager {
    var onToggleRecordingRequested: (() -> Void)?

    private let doubleTapInterval: TimeInterval = 0.35
    private var globalFlagsMonitor: Any?
    private var localFlagsMonitor: Any?
    private var pollTimer: DispatchSourceTimer?
    private var isOptionPressed = false
    private var lastOptionTapAt: Date?

    func startMonitoring(shortcut _: ShortcutDefinition) {
        stopMonitoring()
        globalFlagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleModifierFlags(event.modifierFlags)
        }

        localFlagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleModifierFlags(event.modifierFlags)
            return event
        }

        startPollingModifierFlags()
    }

    func stopMonitoring() {
        if let globalFlagsMonitor {
            NSEvent.removeMonitor(globalFlagsMonitor)
            self.globalFlagsMonitor = nil
        }

        if let localFlagsMonitor {
            NSEvent.removeMonitor(localFlagsMonitor)
            self.localFlagsMonitor = nil
        }

        pollTimer?.cancel()
        pollTimer = nil
        isOptionPressed = false
        lastOptionTapAt = nil
    }

    private func startPollingModifierFlags() {
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now(), repeating: .milliseconds(100))
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            let flags = CGEventSource.flagsState(.combinedSessionState)
            self.handleModifierFlags(NSEvent.ModifierFlags(rawValue: UInt(flags.rawValue)))
        }
        pollTimer = timer
        timer.resume()
    }

    private func handleModifierFlags(_ flags: NSEvent.ModifierFlags) {
        let relevant = flags.intersection([.command, .option, .control, .shift])
        let isOnlyOptionPressed = relevant.contains(.option) && !relevant.contains(.command) && !relevant.contains(.control) && !relevant.contains(.shift)

        switch isOnlyOptionPressed {
        case true:
            beginOptionPress()
        case false:
            endOptionPress()
        }
    }

    private func beginOptionPress() {
        guard !isOptionPressed else { return }
        isOptionPressed = true
        registerOptionTap()
    }

    private func endOptionPress() {
        isOptionPressed = false
    }

    private func registerOptionTap() {
        let now = Date()
        if let lastOptionTapAt, now.timeIntervalSince(lastOptionTapAt) <= doubleTapInterval {
            self.lastOptionTapAt = nil
            onToggleRecordingRequested?()
            return
        }

        lastOptionTapAt = now
    }
}
