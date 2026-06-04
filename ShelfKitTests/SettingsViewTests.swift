import XCTest

final class SettingsViewTests: XCTestCase {
    func testSettingsViewDoesNotExposeShelfSizeControls() throws {
        let testsDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let repositoryRoot = testsDirectory.deletingLastPathComponent()
        let settingsViewURL = repositoryRoot.appendingPathComponent("ShelfKit/UI/SettingsView.swift")
        let source = try String(contentsOf: settingsViewURL, encoding: .utf8)
        let activeSource = sourceRemovingComments(from: source)

        XCTAssertFalse(activeSource.contains("Default shelf width"))
        XCTAssertFalse(activeSource.contains("Default shelf height"))
        XCTAssertFalse(activeSource.contains("Slider(value: $preferences.preferredShelfWidth"))
        XCTAssertFalse(activeSource.contains("Slider(value: $preferences.preferredShelfHeight"))
    }

    private func sourceRemovingComments(from source: String) -> String {
        var activeSource = source

        while
            let start = activeSource.range(of: "/*"),
            let end = activeSource.range(of: "*/", range: start.upperBound..<activeSource.endIndex)
        {
            activeSource.removeSubrange(start.lowerBound..<end.upperBound)
        }

        return activeSource
            .components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
            .joined(separator: "\n")
    }
}
