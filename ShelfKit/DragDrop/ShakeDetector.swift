import CoreGraphics
import Foundation

struct ShakeDetector {
    private enum Axis {
        case horizontal
        case vertical
    }

    private struct Sample {
        let point: CGPoint
        let timestamp: TimeInterval
    }

    private let windowDuration: TimeInterval
    private let minimumHorizontalTravel: CGFloat
    private let minimumSegmentDelta: CGFloat
    private let minimumReversals: Int
    private let maximumVerticalDrift: CGFloat

    private var samples: [Sample] = []
    private var hasTriggered = false

    init(
        windowDuration: TimeInterval = 0.75,
        minimumHorizontalTravel: CGFloat = 90,
        minimumSegmentDelta: CGFloat = 12,
        minimumReversals: Int = 2,
        maximumVerticalDrift: CGFloat = 220
    ) {
        self.windowDuration = windowDuration
        self.minimumHorizontalTravel = minimumHorizontalTravel
        self.minimumSegmentDelta = minimumSegmentDelta
        self.minimumReversals = minimumReversals
        self.maximumVerticalDrift = maximumVerticalDrift
    }

    mutating func ingest(point: CGPoint, timestamp: TimeInterval) -> Bool {
        guard hasTriggered == false else {
            return false
        }

        samples.append(Sample(point: point, timestamp: timestamp))
        samples.removeAll { timestamp - $0.timestamp > windowDuration }

        guard samples.count >= 4 else {
            return false
        }

        let xValues = samples.map(\.point.x)
        let yValues = samples.map(\.point.y)
        let horizontalTravel = (xValues.max() ?? point.x) - (xValues.min() ?? point.x)
        let verticalTravel = (yValues.max() ?? point.y) - (yValues.min() ?? point.y)

        let primaryAxis: Axis
        let primaryTravel: CGFloat
        let orthogonalTravel: CGFloat

        if horizontalTravel >= verticalTravel {
            primaryAxis = .horizontal
            primaryTravel = horizontalTravel
            orthogonalTravel = verticalTravel
        } else {
            primaryAxis = .vertical
            primaryTravel = verticalTravel
            orthogonalTravel = horizontalTravel
        }

        guard
            primaryTravel >= minimumHorizontalTravel,
            orthogonalTravel <= maximumVerticalDrift
        else {
            return false
        }

        var lastDirection = 0
        var reversals = 0

        for index in 1..<samples.count {
            let delta: CGFloat
            switch primaryAxis {
            case .horizontal:
                delta = samples[index].point.x - samples[index - 1].point.x
            case .vertical:
                delta = samples[index].point.y - samples[index - 1].point.y
            }

            guard abs(delta) >= minimumSegmentDelta else {
                continue
            }

            let direction = delta > 0 ? 1 : -1
            if lastDirection != 0, direction != lastDirection {
                reversals += 1
            }
            lastDirection = direction
        }

        guard reversals >= minimumReversals else {
            return false
        }

        hasTriggered = true
        return true
    }

    mutating func reset() {
        samples.removeAll()
        hasTriggered = false
    }
}
