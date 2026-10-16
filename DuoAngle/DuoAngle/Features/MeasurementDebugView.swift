#if DEBUG
import SwiftUI

struct MeasurementDebugView: View {
    let measurement: HingeMeasurementManager

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("DEBUG INFORMATION")
            Text("Status: \(measurement.snapshot.status.rawValue)")
            Text("Raw Angle: \(measurement.snapshot.angleDegrees.map { String(format: "%.6f°", $0) } ?? "—")")
            Text("Updates: \(measurement.updateCount)")
            Text("Available: \(measurement.snapshot.isAvailable ? "true" : "false")")
            Text("Last Update: \(measurement.lastUpdate?.formatted(date: .omitted, time: .standard) ?? "—")")
        }
        .font(.system(size: 12, design: .monospaced))
        .foregroundStyle(.white)
        .padding(12)
        .background(.black.opacity(0.85))
        .allowsHitTesting(false)
    }
}
#endif
