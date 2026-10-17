import SwiftUI

struct AddAngleView: View {
    let store: AngleTargetStore
    let measurement: HingeMeasurementManager
    let editing: AngleTarget?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedAngle: Int
    @State private var saveError: String?

    init(store: AngleTargetStore, measurement: HingeMeasurementManager, editing: AngleTarget?) {
        self.store = store
        self.measurement = measurement
        self.editing = editing
        _selectedAngle = State(initialValue: editing?.angle ?? AngleTarget.defaultAngle)
    }

    private var validationMessage: String? {
        if !AngleTarget.validAngles.contains(selectedAngle) { return "角度必须在 0° 到 180° 之间。" }
        if store.contains(selectedAngle, excluding: editing?.id) { return "这个目标角度已存在，请选择其他角度。" }
        return nil
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Spacer(minLength: 12)

                Text("\(selectedAngle)°")
                    .font(.system(size: 72, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(reduceMotion ? .identity : .numericText())
                    .animation(reduceMotion ? nil : .linear(duration: 0.12), value: selectedAngle)
                    .accessibilityLabel("选定角度，\(selectedAngle) 度")

                Picker("目标角度", selection: $selectedAngle) {
                    ForEach(AngleTarget.validAngles, id: \.self) { angle in
                        Text("\(angle)°").tag(angle)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: 320)
                .accessibilityIdentifier("targetAngleWheel")

                let current = CurrentAngleSelection.angle(from: measurement.snapshot)
                VStack(spacing: 4) {
                    Button("使用当前角度") {
                        if let current = CurrentAngleSelection.angle(from: measurement.snapshot) {
                            selectedAngle = current
                        }
                    }
                    .disabled(current == nil)
                    .accessibilityHint(current == nil ? "当前角度不可用，请使用滚轮选择" : "将当前铰链角度复制到滚轮")

                    if current == nil {
                        Text("当前角度不可用")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                if let message = validationMessage ?? saveError {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("angleValidationMessage")
                }

                Spacer(minLength: 12)
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: .systemBackground))
            .navigationTitle(editing == nil ? "新增角度" : "编辑角度")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button("保存") { save() }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .controlSize(.large)
                    .disabled(validationMessage != nil)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.regularMaterial)
            }
        }
    }

    private func save() {
        guard validationMessage == nil else { return }
        do {
            if let editing {
                try store.edit(editing.id, angle: selectedAngle)
            } else {
                try store.add(selectedAngle)
            }
            dismiss()
        } catch {
            saveError = "无法保存目标角度，请重试。"
        }
    }
}
