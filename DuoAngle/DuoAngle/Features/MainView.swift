import SwiftUI

struct MainView: View {
    let targets: AngleTargetStore
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
    @State private var hasActiveDivision = false
    @State private var lastStatusChange: Date?
    @State private var lastDivisionChange: Date?
    #endif

    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()
            DuoDisplayManager.present {
                Text(measurement.displayText)
                    .font(.system(size: measurement.snapshot.isAvailable ? 96 : 28, weight: .light))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
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
                    MeasurementDebugView(
                        measurement: measurement,
                        hasActiveDivision: hasActiveDivision,
                        lastStatusChange: lastStatusChange,
                        lastDivisionChange: lastDivisionChange
                    )
                }
                Button(showsDiagnostics ? "隐藏诊断" : "显示诊断") {
                    showsDiagnostics.toggle()
                }
                .font(.caption)
                .foregroundStyle(.primary)
                .padding(12)
            }
            GeometryReader { geometry in
                Color.clear
                    .onChange(of: geometry.reservedRegions(kind: .division).contains(where: \.isActive), initial: true) { oldValue, newValue in
                        if oldValue != newValue { lastDivisionChange = .now }
                        hasActiveDivision = newValue
                    }
            }
            .allowsHitTesting(false)
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
                AngleSettingView(store: targets, measurement: measurement)
            case .supportDevelopment:
                SupportDevelopmentView()
            }
        }
        // The public SwiftUI hinge API is view-bound on iOS 27.1+.
        .onHingeChange(isEnabled: scenePhase == .active) { _, context in
            let (angle, status) = SwiftUIHingeAdapter.measurement(from: context)
            #if DEBUG
            if measurement.snapshot.status != status { lastStatusChange = .now }
            #endif
            measurement.receive(angleRadians: angle, status: status)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { measurement.clear() }
        }
        .onDisappear { measurement.clear() }
    }
}
