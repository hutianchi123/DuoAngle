import SwiftUI

struct CompatibilityUnconfirmedView: View {
    let supportPurchases: SupportProductManager
    @State private var showingSupport = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text("尚未确认设备兼容性")
                .font(.largeTitle.weight(.semibold))
                .multilineTextAlignment(.center)
            Text("有度尚未验证此 iPhone 机型。确认兼容性前，角度测量功能暂不可用。")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Button("支持开发") { showingSupport = true }
                .font(.body.weight(.medium))
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .buttonStyle(.bordered)
        }
        .padding(28)
        .frame(maxWidth: 560, maxHeight: .infinity)
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
        .sheet(isPresented: $showingSupport) {
            SupportDevelopmentView(manager: supportPurchases)
        }
    }
}
