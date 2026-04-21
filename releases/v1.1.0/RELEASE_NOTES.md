# HoldIt v1.1.0

Release date: 2026-04-21

## Highlights

- Added the first notch-native drop experience for notch-equipped MacBooks.
- New compact notch box shows a leading file/status icon and the total shelf item count.
- Added active hover styling so valid drops are confirmed directly on the notch surface.
- Kept the existing floating shelf behavior unchanged on Macs without a notch.

## Included Files

- `ShelfKit-v1.1.0-macOS.zip`: release build package
- `SHA256SUMS.txt`: package checksum

## Notes

- The distributable is built from the `ShelfKit` target, which is the internal app target used by HoldIt.
- Runtime tests could not be executed in the current sandbox because macOS test runner services are blocked, but the app builds successfully in Release configuration.
