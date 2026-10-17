import SwiftUI

struct BottomActionBar: View {
    let onAngleSetting: () -> Void
    let onSupportDevelopment: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            // The app targets iOS 27.1, so the iOS 26 Liquid Glass APIs are always available.
            GlassEffectContainer(spacing: 12) {
                HStack(spacing: 12) {
                    angleButton
                    supportButton
                }
            }
            GlassEffectContainer(spacing: 10) {
                VStack(spacing: 10) {
                    angleButton
                    supportButton
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(Color(uiColor: .systemBackground))
    }

    private var angleButton: some View {
        Button(action: onAngleSetting) {
            Text("设定角度")
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(minWidth: 120, minHeight: 44)
        }
        .buttonStyle(.glass)
        .tint(Color.primary)
        .accessibilityLabel("设定角度")
    }

    private var supportButton: some View {
        Button(action: onSupportDevelopment) {
            Text("支持开发")
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(minWidth: 120, minHeight: 44)
        }
        .buttonStyle(.glass)
        .tint(Color.primary)
        .accessibilityLabel("支持开发")
    }
}
