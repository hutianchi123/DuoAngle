import Foundation

enum AngleMath {
    nonisolated static func degrees(fromRadians radians: Double) -> Double {
        radians * 180 / .pi
    }

    nonisolated static func radians(fromDegrees degrees: Double) -> Double {
        degrees * .pi / 180
    }

    nonisolated static func normalizedDegrees(_ degrees: Double) -> Double {
        let remainder = degrees.truncatingRemainder(dividingBy: 360)
        let normalized = remainder < 0 ? remainder + 360 : remainder
        return normalized.roundedIfVeryClose(to: 0)
    }

    nonisolated static func clampedDegrees(_ degrees: Double, range: ClosedRange<Double> = 0...180) -> Double {
        min(max(degrees, range.lowerBound), range.upperBound)
    }
}

private extension Double {
    nonisolated func roundedIfVeryClose(to value: Double, tolerance: Double = 1e-12) -> Double {
        abs(self - value) < tolerance ? value : self
    }
}
