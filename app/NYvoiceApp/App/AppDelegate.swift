import AppKit
import Combine
import Foundation
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private(set) var container = AppContainer()
    private var menuBarController: MenuBarController?
    private var modalWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private var cancellable: AnyCancellable?
    private var globalEscapeKeyMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        menuBarController = MenuBarController(container: container)
        menuBarController?.onOpenSettings = { [weak self] in
            self?.showSettingsWindow()
        }
        menuBarController?.onRunEnvironmentCheck = { [weak self] in
            Task { @MainActor in
                await self?.runAndPresentEnvironmentCheck(force: true)
            }
        }
        container.start()
        bindSessionState()
        Task { @MainActor in
            await runAndPresentEnvironmentCheck(force: false)
        }
    }

    private func bindSessionState() {
        cancellable = container.sessionController.$state.sink { [weak self] state in
            guard let self else { return }
            if state != .idle {
                showRecordingModal()
            } else {
                hideRecordingModal()
            }
        }
    }

    private func showRecordingModal() {
        if modalWindow != nil {
            return
        }

        let view = RecordingModalView(controller: container.sessionController)
        let hosting = NSHostingController(rootView: view)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 220),
            styleMask: [.titled, .utilityWindow, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.title = "Recording"
        panel.level = .floating
        panel.contentViewController = hosting
        panel.center()
        panel.orderFrontRegardless()
        modalWindow = panel
        installEscapeKeyMonitorIfNeeded()
    }

    private func showSettingsWindow() {
        if let window = settingsWindow {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            return
        }

        let hosting = NSHostingController(rootView: SettingsView(container: container))
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 500),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        window.contentViewController = hosting
        window.setContentSize(NSSize(width: 720, height: 500))
        window.minSize = NSSize(width: 720, height: 500)
        window.maxSize = NSSize(width: 720, height: 500)
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self
        settingsWindow = window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private func hideRecordingModal() {
        modalWindow?.close()
        modalWindow = nil
        removeEscapeKeyMonitor()
    }

    private func installEscapeKeyMonitorIfNeeded() {
        guard globalEscapeKeyMonitor == nil else { return }
        globalEscapeKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return }
            guard event.keyCode == 53 else { return } // Escape key
            guard self.modalWindow != nil else { return }
            guard self.container.sessionController.state == .recording else { return }
            Task { @MainActor in
                await self.container.sessionController.cancelRecording()
            }
        }
    }

    private func removeEscapeKeyMonitor() {
        guard let globalEscapeKeyMonitor else { return }
        NSEvent.removeMonitor(globalEscapeKeyMonitor)
        self.globalEscapeKeyMonitor = nil
    }

    private func runAndPresentEnvironmentCheck(force: Bool) async {
        let issues = await container.runStartupChecks(force: force)
        guard !issues.isEmpty || force else {
            return
        }

        let alert = NSAlert()
        alert.alertStyle = issues.isEmpty ? .informational : .warning
        alert.messageText = issues.isEmpty ? "Environment check passed" : "Environment issues detected"
        alert.informativeText = issues.isEmpty ? "All startup checks passed." : formatIssues(issues)
        alert.addButton(withTitle: "OK")
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }

    private func formatIssues(_ issues: [StartupCheckIssue]) -> String {
        issues.enumerated().map { index, issue in
            "\(index + 1). \(issue.title)\n   \(issue.suggestion)"
        }.joined(separator: "\n\n")
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, window === settingsWindow else {
            return
        }
        settingsWindow = nil
    }
}
