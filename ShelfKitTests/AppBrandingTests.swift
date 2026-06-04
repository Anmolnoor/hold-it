import XCTest

final class AppBrandingTests: XCTestCase {
    func testHostBundleUsesHoldItBranding() {
        let info = Bundle.main.infoDictionary

        XCTAssertEqual(info?["CFBundleDisplayName"] as? String, "HoldIt")
        XCTAssertEqual(info?["CFBundleName"] as? String, "HoldIt")
        XCTAssertEqual(info?["CFBundleExecutable"] as? String, "HoldIt")
    }
}
