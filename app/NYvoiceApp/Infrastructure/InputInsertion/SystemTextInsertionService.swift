import AppKit
import Foundation

final class SystemTextInsertionService: TextInsertionService {
    func insert(text: String) throws {
        do {
            try typeText(text)
        } catch {
            try pasteViaClipboard(text)
        }
    }

    private func typeText(_ text: String) throws {
        for scalar in text.unicodeScalars {
            guard let down = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true),
                  let up = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false) else {
                throw DomainError.insertion("Unable to create keyboard event")
            }

            var value = UInt16(scalar.value)
            down.keyboardSetUnicodeString(stringLength: 1, unicodeString: &value)
            up.keyboardSetUnicodeString(stringLength: 1, unicodeString: &value)
            down.post(tap: .cghidEventTap)
            up.post(tap: .cghidEventTap)
        }
    }

    private func pasteViaClipboard(_ text: String) throws {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        guard let down = CGEvent(keyboardEventSource: nil, virtualKey: 9, keyDown: true),
              let up = CGEvent(keyboardEventSource: nil, virtualKey: 9, keyDown: false) else {
            throw DomainError.insertion("Unable to create paste event")
        }

        down.flags = .maskCommand
        up.flags = .maskCommand
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }
}
