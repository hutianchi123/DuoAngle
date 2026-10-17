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

    init() {
        if ProcessInfo.processInfo.arguments.contains("-ui-testing-targets"),
           let defaults = UserDefaults(suiteName: "DuoAngle.UITests") {
            defaults.removePersistentDomain(forName: "DuoAngle.UITests")
            _targets = State(initialValue: AngleTargetStore(defaults: defaults))
        } else {
            _targets = State(initialValue: AngleTargetStore())
        }
    }

    var body: some Scene {
        WindowGroup {
            MainView(targets: targets)
        }
    }
}
