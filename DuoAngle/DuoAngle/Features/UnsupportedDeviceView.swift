import SwiftUI

struct UnsupportedDeviceView: View {
    let supportPurchases: SupportProductManager
    @State private var showingSupport = false
    @Environment(\.openURL) private var openURL

    private let appleURL = URL(string: "https://www.apple.com/iphone/")!

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    Image(systemName: "rectangle.split.2x1")
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                        .padding(.bottom, 28)
                    Text("此设备暂不支持")
                        .font(.largeTitle.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 14)
                    Text("有度专为 iPhone Duo 设计，请在 iPhone Duo 上使用角度测量功能。")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 28)
                        .padding(.bottom, 28)
                    Button {
                        openURL(appleURL)
                    } label: {
                        Label("了解 iPhone Duo", systemImage: "arrow.up.right")
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(Color.white)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("打开 Apple 官方 iPhone 信息页面")
                }
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity, minHeight: geometry.size.height, alignment: .center)
                .padding(.horizontal, 28)
                .padding(.vertical, 28)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                supportAction
            }
            .background(Color(uiColor: .systemBackground).ignoresSafeArea())
        }
        .sheet(isPresented: $showingSupport) {
            SupportDevelopmentView(manager: supportPurchases)
        }
    }

    private var supportAction: some View {
        VStack(spacing: 0) {
            Button("支持开发") { showingSupport = true }
                .font(.body.weight(.medium))
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: 560)
        .padding(.horizontal, 12)
        .background(Color(uiColor: .systemBackground))
    }
}
