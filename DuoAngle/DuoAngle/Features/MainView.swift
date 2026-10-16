import SwiftUI

struct MainView: View {
    @State private var measurement = HingeMeasurementManager()
    @Environment(\.scenePhase) private var scenePhase
    #if DEBUG
    @State private var showsDiagnostics = false
    #endif

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Text(measurement.displayText)
                .font(.system(size: measurement.snapshot.isAvailable ? 96 : 28, weight: .light))
                .monospacedDigit()
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            #if DEBUG
            VStack {
                Spacer()
                if showsDiagnostics {
                    MeasurementDebugView(measurement: measurement)
                }
                Button(showsDiagnostics ? "隐藏诊断" : "显示诊断") {
                    showsDiagnostics.toggle()
                }
                .font(.caption)
                .foregroundStyle(.white)
                .padding(12)
            }
            #endif
        }
        // The public SwiftUI hinge API is view-bound on iOS 27.1+.
        .onHingeChange(isEnabled: scenePhase == .active) { _, context in
            let (angle, status) = SwiftUIHingeAdapter.measurement(from: context)
            measurement.receive(angleRadians: angle, status: status)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { measurement.clear() }
        }
        .onDisappear { measurement.clear() }
    }
}
