import SwiftUI

struct MainView: View {
    let targets: AngleTargetStore
    let supportPurchases: SupportProductManager
    private enum Destination: String, Identifiable {
        case angleSetting
        case supportDevelopment

        var id: String { rawValue }
    }

    @State private var measurement = HingeMeasurementManager()
    @State private var targetMonitor = TargetMonitor()
    @State private var monitoringSessionID: UUID?
    @State private var alertCoordinator = TargetAlertCoordinator(haptics: HapticManager())
    @State private var targetFeedback = TargetReachedFeedbackState()
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
                angleReadout
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
                SupportDevelopmentView(manager: supportPurchases)
            }
        }
        // The public SwiftUI hinge API is view-bound on iOS 27.1+.
        .onHingeChange(isEnabled: scenePhase == .active) { _, context in
            let (angle, status) = SwiftUIHingeAdapter.measurement(from: context)
            #if DEBUG
            if measurement.snapshot.status != status { lastStatusChange = .now }
            #endif
            measurement.receive(angleRadians: angle, status: status)
            processMeasurement()
        }
        .onAppear { beginMonitoringIfNeeded() }
        .onChange(of: targets.targets) { _, updatedTargets in
            guard monitoringSessionID != nil else { return }
            targetMonitor.synchronizeTargets(updatedTargets, baseline: measurement.snapshot)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                beginMonitoringIfNeeded()
            } else {
                stopMonitoring()
                measurement.clear()
            }
        }
        .onDisappear {
            stopMonitoring()
            measurement.clear()
        }
        .task { await supportPurchases.start() }
        .task(id: targetFeedback.presentationID) {
            guard targetFeedback.isVisible else { return }
            let presentationID = targetFeedback.presentationID
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            targetFeedback.dismiss(ifPresentationID: presentationID)
        }
    }

    @ViewBuilder
    private var angleReadout: some View {
        if measurement.snapshot.isAvailable {
            Text(measurement.displayText)
                .font(.system(size: 96, weight: .light))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .padding(24)
                .contentTransition(reduceMotion ? .identity : .numericText())
                .animation(reduceMotion ? nil : .linear(duration: 0.1), value: measurement.displayText)
                .overlay(alignment: .trailing) {
                    if targetFeedback.isVisible {
                        Image(systemName: "checkmark")
                            .font(.system(size: 26, weight: .medium))
                            .foregroundStyle(.secondary)
                            .offset(x: 40)
                            .transition(reduceMotion ? .identity : .opacity)
                            .accessibilityHidden(true)
                    }
                }
                .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: targetFeedback.isVisible)
                .accessibilityLabel(angleAccessibilityLabel)
        } else {
            Text(measurement.displayText)
                .font(.title.weight(.light))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(24)
                .accessibilityLabel(angleAccessibilityLabel)
        }
    }

    private var angleAccessibilityLabel: String {
        let angle = measurement.snapshot.isAvailable
            ? "当前角度，\(measurement.displayText.replacingOccurrences(of: "°", with: " 度"))"
            : measurement.displayText
        return targetFeedback.isVisible ? "\(angle)，已达到目标角度" : angle
    }

    private func beginMonitoringIfNeeded() {
        guard scenePhase == .active, monitoringSessionID == nil else { return }
        let sessionID = UUID()
        monitoringSessionID = sessionID
        targetMonitor.beginSession(sessionID)
    }

    private func stopMonitoring() {
        monitoringSessionID = nil
        targetMonitor.endSession()
        alertCoordinator.reset()
        targetFeedback.reset()
    }

    private func processMeasurement() {
        guard scenePhase == .active else { return }
        beginMonitoringIfNeeded()
        guard let sessionID = monitoringSessionID else { return }
        let events = targetMonitor.process(
            sample: measurement.snapshot,
            targets: targets.enabledTargets,
            sessionID: sessionID
        )
        if let selected = alertCoordinator.handle(events) {
            targetFeedback.present(selected)
        }
    }
}
