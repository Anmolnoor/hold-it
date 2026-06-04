import XCTest
@testable import ShelfKit

final class UpdateServiceTests: XCTestCase {

    private func freshDefaults() -> UserDefaults {
        let suiteName = "com.shelfkit.update.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    func testFindsAvailableReleaseUpdateWithDmgAsset() async throws {
        let release = GitHubRelease(
            tagName: "v1.1.0",
            htmlURL: URL(string: "https://github.com/Anmolnoor/hold-it/releases/tag/v1.1.0")!,
            draft: false,
            prerelease: false,
            assets: [
                GitHubRelease.Asset(
                    name: "HoldIt-v1.1.0.dmg",
                    browserDownloadURL: URL(string: "https://example.com/HoldIt-v1.1.0.dmg")!
                )
            ]
        )
        let checker = UpdateChecker(client: StubReleaseClient(release: release))

        let update = try await checker.availableUpdate(currentVersion: "0.1")

        XCTAssertEqual(update?.version, "v1.1.0")
        XCTAssertEqual(update?.installerAssetURL, URL(string: "https://example.com/HoldIt-v1.1.0.dmg"))
    }

    func testNoUpdateWhenLatestReleaseMatchesCurrentVersion() async throws {
        let release = GitHubRelease(
            tagName: "v0.1.0",
            htmlURL: URL(string: "https://github.com/Anmolnoor/hold-it/releases/tag/v0.1.0")!,
            draft: false,
            prerelease: false,
            assets: []
        )
        let checker = UpdateChecker(client: StubReleaseClient(release: release))

        let update = try await checker.availableUpdate(currentVersion: "0.1")

        XCTAssertNil(update)
    }

    func testDraftReleaseIsIgnored() async throws {
        let release = GitHubRelease(
            tagName: "v1.1.0",
            htmlURL: URL(string: "https://github.com/Anmolnoor/hold-it/releases/tag/v1.1.0")!,
            draft: true,
            prerelease: false,
            assets: []
        )
        let checker = UpdateChecker(client: StubReleaseClient(release: release))

        let update = try await checker.availableUpdate(currentVersion: "0.1")

        XCTAssertNil(update)
    }

    @MainActor
    func testStartupCheckDoesNothingWhenPreferenceIsDisabled() async {
        let preferences = PreferencesStore(defaults: freshDefaults())
        var didSleep = false
        var didCheck = false
        let scheduler = StartupUpdateScheduler(
            preferences: preferences,
            delay: .seconds(300),
            sleep: { _ in didSleep = true },
            checkForUpdates: { didCheck = true }
        )

        let task = scheduler.scheduleIfNeeded()
        await Task.yield()

        XCTAssertNil(task)
        XCTAssertFalse(didSleep)
        XCTAssertFalse(didCheck)
    }

    @MainActor
    func testStartupCheckSleepsFiveMinutesBeforeCheckingWhenPreferenceIsEnabled() async {
        let preferences = PreferencesStore(defaults: freshDefaults())
        preferences.checkForUpdatesAfterLaunch = true
        var requestedDelay: Duration?
        var didCheck = false
        let scheduler = StartupUpdateScheduler(
            preferences: preferences,
            delay: .seconds(300),
            sleep: { delay in requestedDelay = delay },
            checkForUpdates: { didCheck = true }
        )

        let task = scheduler.scheduleIfNeeded()
        await task?.value

        XCTAssertEqual(requestedDelay, .seconds(300))
        XCTAssertTrue(didCheck)
    }
}

private struct StubReleaseClient: GitHubReleaseClient {
    let release: GitHubRelease

    func latestRelease() async throws -> GitHubRelease {
        release
    }
}
