import CoreGraphics
import XCTest
@testable import ShelfKit

@MainActor
final class PreferencesStoreTests: XCTestCase {

    private func freshDefaults() -> UserDefaults {
        let suiteName = "com.shelfkit.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    // MARK: - Default values

    func testDefaultWidth() {
        let store = PreferencesStore(defaults: freshDefaults())
        XCTAssertEqual(store.preferredShelfWidth, 360)
    }

    func testDefaultHeight() {
        let store = PreferencesStore(defaults: freshDefaults())
        XCTAssertEqual(store.preferredShelfHeight, 420)
    }

    func testDefaultShelfSize() {
        let store = PreferencesStore(defaults: freshDefaults())
        XCTAssertEqual(store.shelfSize, CGSize(width: 360, height: 420))
    }

    // MARK: - Persistence

    func testWidthPersistsToDefaults() {
        let defaults = freshDefaults()
        let store = PreferencesStore(defaults: defaults)

        store.preferredShelfWidth = 500

        XCTAssertEqual(defaults.double(forKey: "preferences.shelfWidth"), 500)
    }

    func testHeightPersistsToDefaults() {
        let defaults = freshDefaults()
        let store = PreferencesStore(defaults: defaults)

        store.preferredShelfHeight = 600

        XCTAssertEqual(defaults.double(forKey: "preferences.shelfHeight"), 600)
    }

    func testRestoredFromDefaults() {
        let defaults = freshDefaults()
        defaults.set(450.0, forKey: "preferences.shelfWidth")
        defaults.set(700.0, forKey: "preferences.shelfHeight")

        let store = PreferencesStore(defaults: defaults)

        XCTAssertEqual(store.preferredShelfWidth, 450)
        XCTAssertEqual(store.preferredShelfHeight, 700)
    }

    // MARK: - updateShelfSize clamping

    func testUpdateShelfSizeClampsMinimum() {
        let store = PreferencesStore(defaults: freshDefaults())

        store.updateShelfSize(CGSize(width: 100, height: 100))

        XCTAssertEqual(store.preferredShelfWidth, 300)
        XCTAssertEqual(store.preferredShelfHeight, 240)
    }

    func testUpdateShelfSizeClampsMaximum() {
        let store = PreferencesStore(defaults: freshDefaults())

        store.updateShelfSize(CGSize(width: 1000, height: 2000))

        XCTAssertEqual(store.preferredShelfWidth, 700)
        XCTAssertEqual(store.preferredShelfHeight, 900)
    }

    func testUpdateShelfSizeWithinRangeIsExact() {
        let store = PreferencesStore(defaults: freshDefaults())

        store.updateShelfSize(CGSize(width: 500, height: 500))

        XCTAssertEqual(store.preferredShelfWidth, 500)
        XCTAssertEqual(store.preferredShelfHeight, 500)
    }

    // MARK: - Hotkey description

    func testHotkeyDescription() {
        let store = PreferencesStore(defaults: freshDefaults())
        XCTAssertEqual(store.newShelfHotkeyDescription, "Option-Command-S")
    }
}
