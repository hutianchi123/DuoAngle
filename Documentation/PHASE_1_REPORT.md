# Duo Angle — Phase 1 实施记录

日期：2026-10-16 咩。

## 实现

- 应用入口改用 `MainView`，不再注入自动变化的 Mock 数据咩。
- `MainView` 通过 iOS 27.1 公开的 SwiftUI `onHingeChange(isEnabled:_:)` 接收当前视图层级的 `DeviceHingeContext`，`SwiftUIHingeAdapter` 将 `Angle.radians` 和官方状态映射为应用自身类型咩。
- `HingeMeasurementManager` 用 Observation 发布读数，内部保留 `Double` 弧度精度，显示时才按 Swift 默认的四舍五入规则取整咩。
- 关闭状态清除旧角度并显示“请展开以测量角度”，缺失或无效测量显示“角度暂不可用”，应用离开活动场景时清除旧值咩。
- 主界面使用纯黑背景、白色系统字体与居中角度，DEBUG 构建可显示原始度数、状态、可用性、更新次数和最近更新时间咩。
- 状态变化通过 `Logger` 记录，普通角度更新不逐条记录咩。

## 验证

- Xcode 27.1，Build 27A9275；iOS 设备及模拟器 SDK 27.1；应用和测试最低部署目标 iOS 27.1 咩。
- XcodeBuildMCP 在 iPhone Duo / iOS 27.1 模拟器上完成 Debug 构建与启动，截图观察到系统铰链读数 `128°` 咩。
- XcodeBuildMCP 的 Release 模拟器构建也成功，DEBUG 诊断代码由条件编译排除咩。
- XcodeBuildMCP 的模拟器测试结果为 10 通过、0 失败、0 跳过，覆盖单位换算、精度保留、重复更新、关闭与不可用状态和无效角度咩。
- 用户提供的 Simulator 窗口截图显示折叠状态下的“请展开以测量角度”与黑白主界面，未显示旧角度咩。
- MCP 后续截图仅得到全黑画面，而辅助功能快照仍列出“显示诊断”按钮；这可能与 Duo 模拟器显示区域或截图通道有关，诊断面板的视觉呈现仍未确认咩。
- 本次没有实体 iPhone Duo，因此真实铰链变化、精度、延迟、完全关闭和完全打开的实际过渡均待硬件验证咩。

## 限制与下一步

- `DeviceHingeContext.hinge == nil` 只能证明当前层级没有可用铰链上下文，不能可靠区分暂时不可用与非 Duo 硬件，因此界面采用中性提示咩。
- 模拟器可验证回调路径，但不能替代实体设备的物理角度与显示区域验证咩。
- 测量管线已把 SDK 类型限制在适配层，Phase 2 可以在不改变读数模型的前提下接入显示区域适配咩。
- 当前状态为“Phase 1 implementation complete; real-device verification pending.”，完整 Phase 1 退出条件尚未满足咩。
