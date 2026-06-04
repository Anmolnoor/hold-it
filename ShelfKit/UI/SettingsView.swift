import SwiftUI

struct SettingsView: View {
    @ObservedObject var preferences: PreferencesStore
    @ObservedObject var updateController: UpdateController
    let createShelf: () -> Void

    var body: some View {
        Form {
            /*
            Section("Shelf") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Default shelf width: \(Int(preferences.preferredShelfWidth)) pt")
                    Slider(value: $preferences.preferredShelfWidth, in: 300...700, step: 10)

                    Text("Default shelf height: \(Int(preferences.preferredShelfHeight)) pt")
                    Slider(value: $preferences.preferredShelfHeight, in: 240...900, step: 10)
                }
                .padding(.vertical, 4)
            }
            */

            Section("General") {
                Toggle("Launch at Login", isOn: launchAtLoginBinding)
            }

            Section("Updates") {
                Toggle("Check for updates after launch", isOn: $preferences.checkForUpdatesAfterLaunch)

                HStack {
                    Button {
                        Task {
                            await updateController.checkAndOpenUpdate()
                        }
                    } label: {
                        Label(updateController.actionTitle, systemImage: updateController.actionSystemImage)
                    }
                    .disabled(updateController.isBusy)

                    if updateController.isBusy {
                        ProgressView()
                            .controlSize(.small)
                    }
                }

                Text(updateController.statusMessage)
                    .foregroundStyle(.secondary)
            }

            Section("Shortcut") {
                Text("New shelf hotkey: \(preferences.newShelfHotkeyDescription)")
                Text("This first pass keeps the shortcut fixed while the panel and drag model settle.")
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Open Shelf", action: createShelf)
            }
        }
        .formStyle(.grouped)
        .padding(20)
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { preferences.launchAtLogin },
            set: { preferences.launchAtLogin = $0 }
        )
    }
}
