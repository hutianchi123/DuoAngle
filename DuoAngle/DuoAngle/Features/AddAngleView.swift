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
            ScrollView {
                VStack(spacing: 16) {
                    Text("\(selectedAngle)°")
                        .font(.system(size: 72, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
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
                        .buttonStyle(.borderless)
                        .frame(minHeight: 44)
                        .disabled(current == nil)
                        .accessibilityHint(current == nil ? "当前角度不可用，请使用滚轮选择" : "将当前铰链角度复制到滚轮")

                        if current == nil {
                            Text("当前角度不可用")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }

                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
            .background(Color(uiColor: .systemBackground))
            .navigationTitle(editing == nil ? "新增角度" : "编辑角度")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 10) {
                    if let message = validationMessage ?? saveError {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityLabel("错误：\(message)")
                            .accessibilityIdentifier("angleValidationMessage")
                    }

                    Button(action: save) {
                        Text("保存")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 50)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.accentColor)
                    .controlSize(.large)
                    .disabled(validationMessage != nil)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(uiColor: .systemBackground))
            }
            .onChange(of: selectedAngle) { _, _ in saveError = nil }
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
