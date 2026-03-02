import SwiftUI

@main
struct NYvoiceAppMain: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(container: appDelegate.container)
                .frame(width: 720, height: 500)
        }
    }
}
