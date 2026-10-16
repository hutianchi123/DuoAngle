# Duo Angle — Phase 2 显示适配报告

日期：2026-10-16 咩。

## 1. 已核实的公开 API

- Xcode 27.1 的 iOS 27.1 SDK 声明 `SwiftUI.ArrangementView`、`ArrangementViewStyle.overlay`、`.split`、`.automatic`，其最低可用版本为 iOS 27.1 咩。
- `.automatic` 解析为 split 布局；苹果的 iPhone Duo 设计指南说明 overlay 布局在部分折叠时将 Primary 和 Secondary 分到两侧，其余情况下 Primary 位于 Secondary 上方咩。
- `GeometryProxy.reservedRegions(kind:options:layoutDirectionBehavior:)` 可读取 `.division` 与 `.occlusion`，返回的区域具有 `frame`、`margins` 和 `isActive`；division 表示内容分隔，occlusion 表示遮挡，二者都不代表整个面板被系统模糊咩。
- `DeviceHingeContext` 只公开可选的 `hinge`，其中有角度和闭合、部分展开、完全展开状态，没有显示面板可见性或系统模糊状态咩。
- UIKit 公开 `UIArrangementViewController` 及 Primary/Secondary 的布局状态，但没有提供比 SwiftUI 容器更直接的系统模糊面板判定；本阶段无需引入 UIKit 场景协调器咩。
- 本次 SDK 与苹果公开文档未发现可直接判定哪块物理面板被系统模糊的 SwiftUI、scene 或 window 属性；应用不能据铰链角度推断该状态咩。
- 依据：[ArrangementView](https://developer.apple.com/documentation/swiftui/arrangementview)、[ArrangementViewStyle.automatic](https://developer.apple.com/documentation/swiftui/arrangementviewstyle/automatic)、[GeometryProxy](https://developer.apple.com/documentation/swiftui/geometryproxy)、[ReservedRegion](https://developer.apple.com/documentation/swiftui/reservedregion)、[iPhone Duo 设计指南](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo) 咩。

## 2. 实现

`DuoDisplayManager` 把唯一读数放在 `ArrangementView` 的 Primary 中，Secondary 为空，使用公开的 `.overlay` 样式交给系统根据场景几何和折痕区域布局咩。
完全展开时 Primary 覆盖可用全屏并居中；部分展开时系统把 Primary 安排在分隔线一侧，避免跨越铰链咩。
应用不维护由角度驱动的左右屏状态，不读取保留区域来猜测模糊面板，也不为读数更新施加动画咩。
未知或不支持的显示排列由系统容器按当前可用几何回退，应用不合成区域信息咩。
Phase 1 的 `onHingeChange`、测量管理器、闭合清值、白色大字、黑色背景和 Debug 诊断均保留咩。

## 3. 模拟器姿态观察

| 姿态 | 观察结果 |
| --- | --- |
| Closed | 外屏显示“请展开以测量角度”，旧角度消失，仅一个提示咩。 |
| Partially Open | 内屏显示单个约 128°–132° 读数，位于右侧可见区域中央，没有跨过中间分隔线咩。 |
| Open | 内屏显示单个 180° 读数，位于整个可用区域中央咩。 |
| 反向切换 | Closed → Partially Open 后读数回到右侧区域，状态与数值恢复更新咩。 |

以上由 iPhone Duo / iOS 27.1 模拟器的 Device Hub 姿态控件、画面和辅助功能树观察得到咩。
姿态控件提供离散状态，本次未验证任意连续折叠角度或每一帧过渡，因此“无闪烁”仅限观察到的离散切换画面咩。
Debug 诊断展开后显示 partiallyOpen、原始角度、更新次数和可用性咩。

## 4. 构建与测试

Debug 模拟器构建成功咩。
`xcodebuild test` 退出码为 0，原有 8 个单元测试和 2 个 UI 测试均通过，包含测量精度、闭合清值和应用启动检查咩。
Release 模拟器构建成功，Debug 专用诊断在 Release 中由条件编译排除咩。

## 5. 未能验证与已知限制

本次没有实体 iPhone Duo，不能验证物理视角下哪块面板清晰、哪块面板被系统模糊，也不能证明读数在所有真实折叠姿态中均可见咩。
模拟器画面证明了系统分区布局和可读性，但不证明真机的模糊策略或物理铰链精度咩。
没有公开的系统模糊信号，若真机把 Primary 所在面板模糊，需要依据实际设备行为重新评估公开布局方案；当前不使用私有 API 或角度阈值猜测咩。

**Phase 2 simulator implementation complete; physical display and system-blur verification pending.** 咩。

## 6. 真机验收清单

- 在 Closed、不同部分展开角度、完全展开，以及反向折叠过程中观察唯一读数是否始终位于用户可见且清晰的区域咩。
- 检查竖屏、横屏、前后台恢复、场景尺寸变化和系统模糊层出现或消失时是否稳定居中且不跨折痕咩。
- 核对闭合瞬间旧值清除、读数实时性、无重复数字和无明显闪烁咩。
- 记录真机上系统保留区域、活动区域和模糊行为是否与模拟器一致，并在必要时只依据公开 API 修正咩。

## 7. Phase 3 准备状态

当前单读数布局可作为 Phase 3 主界面的基础，但真机可见性是发布前必须完成的验收项咩。
Phase 3 添加底部操作时，应保持导航在 `ArrangementView` 外，并再次检查系统分区下的控件位置咩。
