import AppKit
import Combine
import Foundation

struct GitHubRelease: Decodable {
    struct Asset: Decodable {
        let name: String
        let browserDownloadURL: URL

        private enum CodingKeys: String, CodingKey {
            case name
            case browserDownloadURL = "browser_download_url"
        }
    }

    let tagName: String
    let htmlURL: URL
    let draft: Bool
    let prerelease: Bool
    let assets: [Asset]

    var installerAssetURL: URL? {
        let candidates = assets.filter { asset in
            let lowercasedName = asset.name.lowercased()
            return lowercasedName.hasSuffix(".dmg") || lowercasedName.hasSuffix(".zip")
        }

        return candidates.first { $0.name.lowercased().hasSuffix(".dmg") }?.browserDownloadURL
            ?? candidates.first?.browserDownloadURL
    }

    private enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
        case draft
        case prerelease
        case assets
    }
}

protocol GitHubReleaseClient {
    func latestRelease() async throws -> GitHubRelease
}

struct GitHubAPIReleaseClient: GitHubReleaseClient {
    private let releaseURL: URL

    init(releaseURL: URL = URL(string: "https://api.github.com/repos/Anmolnoor/hold-it/releases/latest")!) {
        self.releaseURL = releaseURL
    }

    func latestRelease() async throws -> GitHubRelease {
        var request = URLRequest(url: releaseURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("HoldIt", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode)
        else {
            throw UpdateError.releaseUnavailable
        }

        return try JSONDecoder().decode(GitHubRelease.self, from: data)
    }
}

struct AppUpdate: Equatable {
    let version: String
    let releaseURL: URL
    let installerAssetURL: URL?
}

struct UpdateChecker {
    let client: GitHubReleaseClient

    func availableUpdate(currentVersion: String) async throws -> AppUpdate? {
        let release = try await client.latestRelease()

        guard release.draft == false,
              release.prerelease == false,
              AppVersion(release.tagName) > AppVersion(currentVersion)
        else {
            return nil
        }

        return AppUpdate(
            version: release.tagName,
            releaseURL: release.htmlURL,
            installerAssetURL: release.installerAssetURL
        )
    }
}

enum UpdateError: LocalizedError {
    case releaseUnavailable
    case cannotOpenUpdate

    var errorDescription: String? {
        switch self {
        case .releaseUnavailable:
            return "Could not read the latest GitHub Release."
        case .cannotOpenUpdate:
            return "Could not open the downloaded update."
        }
    }
}

@MainActor
final class UpdateController: ObservableObject {
    enum State: Equatable {
        case idle
        case checking
        case upToDate
        case updateAvailable(AppUpdate)
        case downloading(String)
        case openedUpdate(String)
        case failed(String)
    }

    @Published private(set) var state: State = .idle

    private let checker: UpdateChecker
    private let currentVersion: () -> String
    private let downloadUpdate: (URL) async throws -> URL
    private let openURL: (URL) -> Bool

    init(
        checker: UpdateChecker = UpdateChecker(client: GitHubAPIReleaseClient()),
        currentVersion: @escaping () -> String = {
            Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
        },
        downloadUpdate: @escaping (URL) async throws -> URL = UpdateController.downloadUpdate(from:),
        openURL: @escaping (URL) -> Bool = { NSWorkspace.shared.open($0) }
    ) {
        self.checker = checker
        self.currentVersion = currentVersion
        self.downloadUpdate = downloadUpdate
        self.openURL = openURL
    }

    var availableUpdate: AppUpdate? {
        guard case .updateAvailable(let update) = state else {
            return nil
        }

        return update
    }

    var isBusy: Bool {
        switch state {
        case .checking, .downloading:
            return true
        case .idle, .upToDate, .updateAvailable, .openedUpdate, .failed:
            return false
        }
    }

    var actionTitle: String {
        availableUpdate == nil ? "Check for Updates" : "Update Now"
    }

    var actionSystemImage: String {
        availableUpdate == nil ? "arrow.clockwise" : "arrow.down.circle"
    }

    var statusMessage: String {
        switch state {
        case .idle:
            return "Updates are checked from GitHub Releases."
        case .checking:
            return "Checking for updates..."
        case .upToDate:
            return "HoldIt is up to date."
        case .updateAvailable(let update):
            return "HoldIt \(update.version) is available."
        case .downloading(let version):
            return "Downloading HoldIt \(version)..."
        case .openedUpdate(let version):
            return "Opened HoldIt \(version)."
        case .failed(let message):
            return message
        }
    }

    func checkForUpdates() async {
        state = .checking

        do {
            if let update = try await checker.availableUpdate(currentVersion: currentVersion()) {
                state = .updateAvailable(update)
            } else {
                state = .upToDate
            }
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func checkAndOpenUpdate() async {
        if let update = availableUpdate {
            await open(update)
            return
        }

        state = .checking

        do {
            guard let update = try await checker.availableUpdate(currentVersion: currentVersion()) else {
                state = .upToDate
                return
            }

            await open(update)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    private func open(_ update: AppUpdate) async {
        guard let installerAssetURL = update.installerAssetURL else {
            state = openURL(update.releaseURL)
                ? .openedUpdate(update.version)
                : .failed(UpdateError.cannotOpenUpdate.localizedDescription)
            return
        }

        state = .downloading(update.version)

        do {
            let downloadedUpdate = try await downloadUpdate(installerAssetURL)
            state = openURL(downloadedUpdate)
                ? .openedUpdate(update.version)
                : .failed(UpdateError.cannotOpenUpdate.localizedDescription)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    private static func downloadUpdate(from url: URL) async throws -> URL {
        let (temporaryURL, response) = try await URLSession.shared.download(from: url)
        if let httpResponse = response as? HTTPURLResponse,
           (200..<300).contains(httpResponse.statusCode) == false {
            throw UpdateError.releaseUnavailable
        }

        let filename = url.lastPathComponent.isEmpty ? "HoldIt-update" : url.lastPathComponent
        let destinationURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }

        try FileManager.default.moveItem(at: temporaryURL, to: destinationURL)
        return destinationURL
    }
}

@MainActor
final class StartupUpdateScheduler {
    private let preferences: PreferencesStore
    private let delay: Duration
    private let sleep: (Duration) async throws -> Void
    private let checkForUpdates: () async -> Void
    private var task: Task<Void, Never>?

    init(
        preferences: PreferencesStore,
        delay: Duration = .seconds(300),
        sleep: @escaping (Duration) async throws -> Void = { try await Task.sleep(for: $0) },
        checkForUpdates: @escaping () async -> Void
    ) {
        self.preferences = preferences
        self.delay = delay
        self.sleep = sleep
        self.checkForUpdates = checkForUpdates
    }

    @discardableResult
    func scheduleIfNeeded() -> Task<Void, Never>? {
        guard preferences.checkForUpdatesAfterLaunch else {
            return nil
        }

        let delay = self.delay
        let sleep = self.sleep
        let checkForUpdates = self.checkForUpdates
        let task = Task { @MainActor in
            do {
                try await sleep(delay)
                await checkForUpdates()
            } catch {
            }
        }

        self.task = task
        return task
    }

    deinit {
        task?.cancel()
    }
}

private struct AppVersion: Comparable {
    let components: [Int]

    init(_ rawValue: String) {
        let normalizedValue = rawValue.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
        let parsedComponents = normalizedValue.split(separator: ".").map { component in
            let numericPrefix = component.prefix { $0.isNumber }
            return Int(numericPrefix) ?? 0
        }

        components = parsedComponents.isEmpty ? [0] : parsedComponents
    }

    static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
        let count = max(lhs.components.count, rhs.components.count)

        for index in 0..<count {
            let lhsComponent = index < lhs.components.count ? lhs.components[index] : 0
            let rhsComponent = index < rhs.components.count ? rhs.components[index] : 0

            if lhsComponent != rhsComponent {
                return lhsComponent < rhsComponent
            }
        }

        return false
    }
}
