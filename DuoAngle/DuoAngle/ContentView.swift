//
//  ContentView.swift
//  DuoAngle
//
//  Created by 胡天驰 on 9/19/26.
//

import SwiftUI

struct ContentView: View {
    @State private var targets = AngleTargetStore()

    var body: some View {
        MainView(targets: targets)
    }
}
