# HoldIt

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-brightgreen.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5-orange.svg)](https://swift.org)

A macOS menu bar utility for drag-and-drop file collection shelves.

<!-- TODO: Add screenshot -->
<!-- ![HoldIt Screenshot](docs/screenshot.png) -->

## Features

- **Floating shelves** — temporary collection panels that hover above other windows
- **Shake-to-summon** — shake your cursor while dragging to instantly open a preview shelf
- **Global hotkey** — press Option-Command-S to create a new shelf anytime
- **Drag in, drag out** — drop files, folders, text, and URLs onto a shelf, then drag them back out to any app
- **Multiple shelves** — open several shelves at once with cascade positioning
- **Menu bar integration** — lives in the menu bar, never clutters your dock
- **Configurable dimensions** — adjust shelf width and height to your preference
- **Launch at login** — start HoldIt automatically when you log in
- **macOS 13 Ventura and later**

## Building from Source

HoldIt is currently distributed as source only. There is no prebuilt notarized DMG; download a GitHub source archive or clone the repository and build the app locally.

### Requirements

- macOS 13.0+
- Xcode 15+ (Swift 5)

### Setup

```bash
git clone git@github.com:Anmolnoor/hold-it.git
cd hold-it
open HoldIt.xcodeproj
```

Select the **HoldIt** scheme in Xcode, then build and run (Cmd+R).

> **Note:** HoldIt runs as a menu bar utility (no dock icon). After launching, look for the icon in the menu bar.

### Local Install

To keep HoldIt on your Mac, build the **HoldIt** scheme in Xcode, open the build products folder, and copy **HoldIt.app** to `/Applications`.

## Usage

- **Create a shelf** — click the menu bar icon and select "New Shelf", or press **Option-Command-S**
- **Shake gesture** — while dragging a file, shake your mouse horizontally to summon a preview shelf
- **Collect items** — drop files, folders, text snippets, or URLs onto any shelf
- **Export items** — drag items from a shelf to another app
- **Settings** — accessible from the menu bar icon

## Architecture

HoldIt uses the internal module name `ShelfKit`. The codebase is organized as:

| Directory | Purpose |
|-----------|---------|
| `App/` | Application lifecycle, menu bar controller, settings window |
| `Domain/` | Core models (`Shelf`, `ShelfItem`) |
| `DragDrop/` | Global drag monitoring, drop handling, shake detection, hotkeys |
| `Storage/` | UserDefaults-based preferences |
| `UI/` | SwiftUI views, view model, presentation modes |
| `Windowing/` | NSPanel management, screen positioning, window coordination |

Built with AppKit + SwiftUI, Combine for reactive state, and Carbon for global hotkey support.

## Contributing

Contributions are welcome! Please read the [Contributing Guide](CONTRIBUTING.md) before submitting a pull request.

If you find a bug or have a feature idea, please [open an issue](https://github.com/Anmolnoor/hold-it/issues/new/choose).

## License

This project is licensed under the GNU General Public License v3.0 — see the [LICENSE](LICENSE) file for details.
