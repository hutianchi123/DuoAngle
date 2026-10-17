import SwiftUI

struct SupportDevelopmentView: View {
    let manager: SupportProductManager

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    Image(systemName: "heart")
                        .font(.system(size: 34, weight: .light))
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                        .padding(.bottom, 24)

                    Text("为热爱，创造更多可能。")
                        .font(.title2.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 28)

                    supportCopy

                    purchaseArea
                        .padding(.top, 36)

                    Text("感谢你的支持，让好奇心继续生长。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 28)
                }
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 28)
                .padding(.vertical, 36)
            }
            .background(Color(uiColor: .systemBackground))
            .navigationTitle("支持开发")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .task {
                if manager.product == nil {
                    await manager.loadProduct()
                }
            }
            .task(id: manager.state) {
                guard manager.state == .succeeded else { return }
                try? await Task.sleep(for: .seconds(2))
                guard !Task.isCancelled else { return }
                manager.acknowledgeSuccess()
            }
        }
    }

    private var supportCopy: some View {
        VStack(spacing: 22) {
            Text("Duo Angle 诞生于一个简单的想法：\n让每一次折叠，都成为一次测量。")
            Text("如果你喜欢这款小工具，\n不妨请开发者喝杯咖啡。")
            Text("所有功能均可免费使用，\n支持完全出于自愿。")
        }
        .font(.body)
        .foregroundStyle(.primary)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var purchaseArea: some View {
        VStack(spacing: 14) {
            Button {
                Task { await manager.purchase() }
            } label: {
                purchaseButtonLabel
                    .frame(maxWidth: 300, minHeight: 52)
                    .contentTransition(reduceMotion ? .identity : .opacity)
            }
            .buttonStyle(.glass)
            .tint(Color.primary)
            .disabled(!isPurchaseEnabled)
            .accessibilityLabel(purchaseAccessibilityLabel)
            .accessibilityHint("这是一项自愿支持，不会解锁额外功能")

            if manager.state == .pending {
                statusText("购买正在等待确认")
            } else if case .failed(let message) = manager.state {
                statusText(message)
            } else if manager.state == .unavailable {
                statusText("暂时无法加载支持选项")
                Button("重试") {
                    Task { await manager.retryLoadingProduct() }
                }
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityLabel("重新加载支持选项")
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: manager.state)
    }

    @ViewBuilder
    private var purchaseButtonLabel: some View {
        switch manager.state {
        case .loadingProduct, .idle:
            HStack(spacing: 10) {
                ProgressView()
                Text("正在加载支持选项")
            }
        case .purchasing:
            HStack(spacing: 10) {
                ProgressView()
                Text("正在处理购买")
            }
        case .pending:
            Label("购买正在等待确认", systemImage: "clock")
        case .succeeded:
            Text("♥ 感谢支持！")
                .fontWeight(.semibold)
        case .productAvailable, .failed:
            if let price = manager.localizedPrice {
                Text("♡ 支持开发 · \(price)")
                    .fontWeight(.semibold)
            }
        case .unavailable:
            Text("♡ 支持开发")
                .fontWeight(.semibold)
        }
    }

    private var isPurchaseEnabled: Bool {
        switch manager.state {
        case .productAvailable, .failed:
            return manager.product != nil
        default:
            return false
        }
    }

    private var purchaseAccessibilityLabel: String {
        switch manager.state {
        case .productAvailable, .failed:
            if let price = manager.localizedPrice {
                return "支持开发，价格 \(price)"
            }
            return "支持开发"
        case .loadingProduct, .idle:
            return "正在加载支持选项"
        case .purchasing:
            return "正在处理购买"
        case .pending:
            return "购买正在等待确认"
        case .succeeded:
            return "感谢支持"
        case .unavailable:
            return "支持选项暂时不可用"
        }
    }

    private func statusText(_ text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }
}
