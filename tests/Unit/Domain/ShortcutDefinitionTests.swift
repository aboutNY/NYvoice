import XCTest
@testable import NYvoiceApp

final class ShortcutDefinitionTests: XCTestCase {
    func testValidShortcut() {
        let shortcut = ShortcutDefinition(keyCode: ShortcutDefinition.default.keyCode, modifiers: ShortcutDefinition.default.modifiers)
        XCTAssertTrue(shortcut.isValid)
    }

    func testInvalidShortcutWithoutModifier() {
        let shortcut = ShortcutDefinition(keyCode: ShortcutDefinition.default.keyCode, modifiers: 0)
        XCTAssertFalse(shortcut.isValid)
    }

    func testInvalidShortcutWithOutOfRangeKeyCode() {
        let shortcut = ShortcutDefinition(keyCode: 200, modifiers: ShortcutDefinition.default.modifiers)
        XCTAssertFalse(shortcut.isValid)
    }
}
