//
//  ContentView.swift
//  DuoAngle
//
//  Created by 胡天驰 on 9/19/26.
//

import SwiftUI

struct ContentView: View {
    @State private var targets = AngleTargetStore()
    @State private var supportPurchases = SupportProductManager()

    var body: some View {
        Group {
            switch DeviceCapabilityResolver.debugOverride ?? DeviceCapabilityResolver.detected {
            case .supported:
                MainView(targets: targets, supportPurchases: supportPurchases)
            case .unsupported:
                UnsupportedDeviceView(supportPurchases: supportPurchases)
            case .unknown:
                CompatibilityUnconfirmedView(supportPurchases: supportPurchases)
            }
        }
    }
}
