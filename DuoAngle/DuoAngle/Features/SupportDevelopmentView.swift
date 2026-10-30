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

                    developerLinks
                        .padding(.top, 36)
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
            Text("有度诞生于一个简单的想法：\n让每一次折叠，都成为一次测量。")
            Text("如果你喜欢这款小工具，\n不妨请开发者喝杯咖啡。")
            Text("所有功能均可免费使用，\n支持完全出于自愿。")
        }
        .font(.body)
        .foregroundStyle(.primary)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var developerLinks: some View {
        VStack(spacing: 0) {
            Link(destination: URL(string: "https://github.com/hutianchi123/DuoAngle")!) {
                developerLinkLabel(
                    symbol: "chevron.left.forwardslash.chevron.right",
                    title: "GitHub",
                    detail: "查看项目源码与更新"
                )
            }

            Divider()

            Link(destination: URL(string: "mailto:hutianchi3622@gmail.com")!) {
                developerLinkLabel(
                    symbol: "envelope",
                    title: "联系开发者",
                    detail: "hutianchi3622@gmail.com"
                )
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private func developerLinkLabel(symbol: String, title: LocalizedStringKey, detail: LocalizedStringKey) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.body)
                .frame(width: 24)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body)
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "arrow.up.right")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle())
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
                Label {
                    Text("支持开发 · \(price)")
                        .fontWeight(.semibold)
                } icon: {
                    Image(systemName: "heart")
                }
            }
        case .unavailable:
            Label("支持开发", systemImage: "heart")
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

    private var purchaseAccessibilityLabel: Text {
        switch manager.state {
        case .productAvailable, .failed:
            if let price = manager.localizedPrice {
                return Text("支持开发，价格 \(price)")
            }
            return Text("支持开发")
        case .loadingProduct, .idle:
            return Text("正在加载支持选项")
        case .purchasing:
            return Text("正在处理购买")
        case .pending:
            return Text("购买正在等待确认")
        case .succeeded:
            return Text("感谢支持")
        case .unavailable:
            return Text("支持选项暂时不可用")
        }
    }

    private func statusText(_ text: String) -> some View {
        Text(LocalizedStringKey(text))
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }
}
