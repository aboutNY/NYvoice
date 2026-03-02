import AppKit
import Foundation

struct ShortcutDefinition: Codable, Equatable {
    var keyCode: UInt16
    var modifiers: UInt

    static let `default` = ShortcutDefinition(
        keyCode: 9,
        modifiers: NSEvent.ModifierFlags.command.union(.shift).rawValue
    )
    static let supportedModifierMask = NSEvent.ModifierFlags.command
        .union(.option)
        .union(.control)
        .union(.shift)
        .rawValue

    var isValid: Bool {
        keyCode <= 127 && modifiers != 0 && (modifiers & ~Self.supportedModifierMask) == 0
    }

    func matches(event: NSEvent) -> Bool {
        let relevant = event.modifierFlags.intersection([.command, .option, .control, .shift])
        return event.keyCode == keyCode && relevant.rawValue == modifiers
    }
}
