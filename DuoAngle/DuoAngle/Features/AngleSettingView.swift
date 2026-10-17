import SwiftUI

struct AngleSettingView: View {
    private enum Editor: Identifiable {
        case add
        case edit(AngleTarget)

        var id: String {
            switch self {
            case .add: "add"
            case .edit(let target): target.id.uuidString
            }
        }

        var target: AngleTarget? {
            if case .edit(let target) = self { return target }
            return nil
        }
    }

    let store: AngleTargetStore
    let measurement: HingeMeasurementManager

    @Environment(\.dismiss) private var dismiss
    @State private var editor: Editor?
    @State private var showRecoveryConfirmation = false

    var body: some View {
        NavigationStack {
            Group {
                if store.isStorageCorrupted {
                    ContentUnavailableView {
                        Label("目标角度数据无法读取", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text("原有数据仍已保留。重置后可重新添加目标角度。")
                    } actions: {
                        Button("重置目标角度", role: .destructive) { showRecoveryConfirmation = true }
                    }
                } else if store.targets.isEmpty {
                    ContentUnavailableView {
                        Label("暂无目标角度", systemImage: "angle")
                    } description: {
                        Text("点击右上角 + 添加目标角度")
                    }
                } else {
                    List {
                        Section {
                            ForEach(store.targets) { target in
                                HStack(alignment: .center, spacing: 12) {
                                    Button {
                                        editor = .edit(target)
                                    } label: {
                                        Text("\(target.angle)°")
                                            .font(.title3.monospacedDigit())
                                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("编辑 \(target.angle) 度")

                                    Toggle("启用 \(target.angle) 度目标角度", isOn: Binding(
                                        get: { target.isEnabled },
                                        set: { newValue in try? store.setEnabled(newValue, for: target.id) }
                                    ))
                                    .labelsHidden()
                                    .accessibilityLabel("启用 \(target.angle) 度目标角度")
                                }
                                .accessibilityElement(children: .contain)
                                .contextMenu {
                                    Button("删除目标角度", role: .destructive) {
                                        try? store.delete(target.id)
                                    }
                                }
                            }
                            .onDelete { offsets in
                                let ids = offsets.map { store.targets[$0].id }
                                for id in ids {
                                    try? store.delete(id)
                                }
                            }
                        } header: {
                            Text("目标角度")
                        } footer: {
                            Text("已启用 \(store.enabledTargets.count) 个目标角度")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: .systemBackground))
            .navigationTitle("设定角度")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("完成") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        editor = .add
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("添加角度")
                    .disabled(store.isStorageCorrupted)
                }
            }
            .sheet(item: $editor) { selected in
                AddAngleView(store: store, measurement: measurement, editing: selected.target)
            }
            .confirmationDialog("重置目标角度数据？", isPresented: $showRecoveryConfirmation) {
                Button("重置并清除损坏数据", role: .destructive) { store.recoverCorruptedStorage() }
            } message: {
                Text("此操作会删除无法读取的原始目标角度数据。")
            }
        }
    }
}
