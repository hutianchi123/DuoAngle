import SwiftUI

struct SupportDevelopmentView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Text("Duo Angle 是一款专为 iPhone Duo 打造的极简角度测量工具。感谢你支持独立开发！")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .padding(32)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(uiColor: .systemBackground))
                .navigationTitle("支持开发")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("完成") { dismiss() }
                    }
                }
        }
    }
}
