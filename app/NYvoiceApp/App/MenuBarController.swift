import AppKit
import Foundation

@MainActor
final class MenuBarController: NSObject {
    private let statusItem: NSStatusItem
    private let container: AppContainer
    var onOpenSettings: (() -> Void)?
    var onRunEnvironmentCheck: (() -> Void)?

    init(container: AppContainer) {
        self.container = container
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        configure()
    }

    private func configure() {
        if let image = loadMenuBarTemplateImage() {
            statusItem.button?.image = image
            statusItem.button?.imagePosition = .imageOnly
            statusItem.button?.title = ""
            statusItem.button?.toolTip = "NYvoice"
        } else {
            statusItem.button?.title = "NYvoice"
        }

        let menu = NSMenu()
        let toggleItem = NSMenuItem(title: "Start/Stop Recording (Double-press Alt)", action: #selector(toggleRecording), keyEquivalent: "")
        menu.addItem(toggleItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Open Settings", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Run Environment Check", action: #selector(runEnvironmentCheck), keyEquivalent: "e"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))

        menu.items.forEach { $0.target = self }
        statusItem.menu = menu
    }

    private func loadMenuBarTemplateImage() -> NSImage? {
        let bundle = Bundle.module
        let resourceURL = bundle.url(
            forResource: "MenuBarTemplate",
            withExtension: "png",
            subdirectory: "Icons"
        ) ?? bundle.url(forResource: "MenuBarTemplate", withExtension: "png")

        guard let url = resourceURL else {
            return nil
        }

        guard let image = NSImage(contentsOf: url) else {
            return nil
        }

        image.isTemplate = true
        image.size = NSSize(width: 18, height: 18)
        return image
    }

    @objc private func toggleRecording() {
        container.sessionController.toggleRecording()
    }

    @objc private func openSettings() {
        onOpenSettings?()
    }

    @objc private func runEnvironmentCheck() {
        onRunEnvironmentCheck?()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
