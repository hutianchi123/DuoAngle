import SwiftUI

struct MainView: View {
    private enum Destination: String, Identifiable {
        case angleSetting
        case supportDevelopment

        var id: String { rawValue }
    }

    @State private var measurement = HingeMeasurementManager()
    @State private var destination: Destination?
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    #if DEBUG
    @State private var showsDiagnostics = false
    #endif

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            DuoDisplayManager.present {
                Text(measurement.displayText)
                    .font(.system(size: measurement.snapshot.isAvailable ? 96 : 28, weight: .light))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .padding(24)
                    .contentTransition(measurement.snapshot.isAvailable && !reduceMotion ? .numericText() : .identity)
                    .animation(measurement.snapshot.isAvailable && !reduceMotion ? .linear(duration: 0.1) : nil, value: measurement.displayText)
                    .accessibilityLabel(measurement.snapshot.isAvailable ? "当前角度，\(measurement.displayText.replacingOccurrences(of: "°", with: " 度"))" : measurement.displayText)
            }

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
        .safeAreaInset(edge: .bottom, spacing: 0) {
            BottomActionBar(
                onAngleSetting: { destination = .angleSetting },
                onSupportDevelopment: { destination = .supportDevelopment }
            )
        }
        .sheet(item: $destination) { selected in
            switch selected {
            case .angleSetting:
                AngleSettingView()
            case .supportDevelopment:
                SupportDevelopmentView()
            }
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
