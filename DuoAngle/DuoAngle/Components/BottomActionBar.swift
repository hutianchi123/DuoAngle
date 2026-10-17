import SwiftUI

struct BottomActionBar: View {
    let onAngleSetting: () -> Void
    let onSupportDevelopment: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                angleButton
                supportButton
            }
            VStack(spacing: 10) {
                angleButton
                supportButton
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(Color.black)
    }

    private var angleButton: some View {
        Button(action: onAngleSetting) {
            Label("设定角度", systemImage: "angle")
                .frame(minWidth: 120, minHeight: 44)
        }
        .buttonStyle(.glass)
        .tint(.white)
        .accessibilityLabel("设定角度")
    }

    private var supportButton: some View {
        Button(action: onSupportDevelopment) {
            Label("支持开发", systemImage: "heart")
                .frame(minWidth: 120, minHeight: 44)
        }
        .buttonStyle(.glass)
        .tint(.white)
        .accessibilityLabel("支持开发")
    }
}
