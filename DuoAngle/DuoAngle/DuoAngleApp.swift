//
//  DuoAngleApp.swift
//  DuoAngle
//
//  Created by 胡天驰 on 9/19/26.
//

import SwiftUI

@main
@MainActor
struct DuoAngleApp: App {
    @State private var targets: AngleTargetStore
    @State private var supportPurchases: SupportProductManager

    init() {
        let isUITesting = ProcessInfo.processInfo.arguments.contains("-ui-testing-targets")
        if isUITesting,
           let defaults = UserDefaults(suiteName: "DuoAngle.UITests") {
            defaults.removePersistentDomain(forName: "DuoAngle.UITests")
            _targets = State(initialValue: AngleTargetStore(defaults: defaults))
        } else {
            _targets = State(initialValue: AngleTargetStore())
        }
        #if DEBUG
        if isUITesting {
            _supportPurchases = State(initialValue: SupportProductManager(service: UITestSupportPurchaseService()))
        } else {
            _supportPurchases = State(initialValue: SupportProductManager())
        }
        #else
        _supportPurchases = State(initialValue: SupportProductManager())
        #endif
    }

    var body: some Scene {
        WindowGroup {
            Group {
                switch DeviceCapabilityResolver.debugOverride ?? DeviceCapabilityResolver.detected {
                case .supported, .unknown:
                    MainView(targets: targets, supportPurchases: supportPurchases)
                case .unsupported:
                    UnsupportedDeviceView(supportPurchases: supportPurchases)
                }
            }
        }
    }
}
