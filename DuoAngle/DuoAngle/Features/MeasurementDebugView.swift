#if DEBUG
import SwiftUI

struct MeasurementDebugView: View {
    let measurement: HingeMeasurementManager
    let hasActiveDivision: Bool
    let lastStatusChange: Date?
    let lastDivisionChange: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("DEBUG INFORMATION")
            Text("Status: \(measurement.snapshot.status.rawValue)")
            Text("Raw Angle: \(measurement.snapshot.angleDegrees.map { String(format: "%.6f°", $0) } ?? "—")")
            Text("Updates: \(measurement.updateCount)")
            Text("Available: \(measurement.snapshot.isAvailable ? "true" : "false")")
            Text("Division: \(hasActiveDivision ? "active" : "inactive")")
            Text("Status Change: \(lastStatusChange?.formatted(date: .omitted, time: .standard) ?? "—")")
            Text("Division Change: \(lastDivisionChange?.formatted(date: .omitted, time: .standard) ?? "—")")
            if let lastStatusChange, let lastDivisionChange {
                Text(String(format: "Division - Status: %+.3fs", lastDivisionChange.timeIntervalSince(lastStatusChange)))
            }
            Text("Last Update: \(measurement.lastUpdate?.formatted(date: .omitted, time: .standard) ?? "—")")
        }
        .font(.system(size: 12, design: .monospaced))
        .foregroundStyle(.primary)
        .padding(12)
        .background(Color(uiColor: .systemBackground).opacity(0.85))
        .allowsHitTesting(false)
    }
}
#endif
