# Phase 3.1 报告：显示响应与系统外观

## 原始问题

- iPhone Duo 从 `fullyOpen` 折叠至 `partiallyOpen` 时，角度读数有时直到动作结束才移至右侧显示区域。咩
- 主界面与两个页面原先固定使用深色，无法跟随系统浅色外观。咩

## 折叠时序与根因

- `MainView` 使用公开的 `onHingeChange` 接收角度和状态，`HingeMeasurementManager` 随回调更新测量状态，`DuoDisplayManager` 使用系统的 `ArrangementView` 放置唯一一份读数。咩
- 数字滚动动画只附着于读数 `Text`，没有施加于 `ArrangementView` 或父级布局，因此没有发现应用层的布局动画造成延迟。咩
- 新增的 DEBUG 面板通过公开的 `GeometryProxy.reservedRegions(kind: .division)` 记录 division 区域活跃状态变化，并分别记录铰链状态变化时间。咩
- 一次从 Open 到 Partially Open 的模拟器观测中，`partiallyOpen` 状态先到，division 区域约 **0.990 秒**后才变为活跃，此时读数已位于右侧。咩
- 一次反向观测中，division 区域变化与 `fullyOpen` 状态变化相差约 **0.021 秒**。咩
- 这些时间只代表 SwiftUI 暴露的状态和保留区域变化，并非系统确认的物理读数迁移事件，因此不能把该差值解释为精确的视觉延迟。咩
- 在已观测的完整折叠转换中，状态变化早于布局可用信息，而单独的 `partiallyOpen` 状态不能证明哪一侧屏幕可见。咩
- 曾检查非活跃 division 区域的宽度作为提前信号，但 `fullyOpen` 与 `partiallyOpen` 两种状态均读得 40 点，无法可靠判断屏幕区域，因此未采用。咩
- 没有找到可安全提前定位右侧的公开信号，故保留 `ArrangementView` 的系统区域选择，不使用角度阈值或私有 API 。咩
- **结论：延迟仍可复现，本阶段未将其认定为已修复**，当前实现维持正确的系统区域选择。咩

## 实际布局与动画变化

- 生产布局保持一份读数和独立的底部安全区按钮栏，未改变 `DuoDisplayManager` 的 `ArrangementView` 策略。咩
- DEBUG 面板新增状态时间、division 活跃状态与两者时间差，相关观测代码仅在 DEBUG 中编译。咩
- 数字仍使用 `.contentTransition(.numericText())` 与限定在 `Text` 上的短动画，并继续在 Reduce Motion 开启时改用无数字滚动的路径。咩
- 原始角度精度、关闭状态清空逻辑和测量订阅没有改动。咩

## 系统浅色与深色外观

- 主界面、底栏及两个页面使用 `Color(uiColor: .systemBackground)`，文本使用语义化 `.primary`，无需应用内切换项。咩
- 在当前模拟器上，深色呈黑底白字，浅色呈白底黑字，原生 `.glass` 按钮随系统外观变化。咩
- 两个 sheet 移除了 `.preferredColorScheme(.dark)`，由系统决定其外观。咩
- DEBUG 面板也采用语义化背景和文字，在两种外观下保持可读。咩
- 项目构建设置中未发现 `UIUserInterfaceStyle` 强制外观项。咩

## 修改文件

- `DuoAngle/DuoAngle/Features/MainView.swift`：动态背景和文字，以及 DEBUG 时序观测。咩
- `DuoAngle/DuoAngle/Features/MeasurementDebugView.swift`：division 与状态时序显示及动态配色。咩
- `DuoAngle/DuoAngle/Components/BottomActionBar.swift`：动态背景和玻璃按钮文字颜色。咩
- `DuoAngle/DuoAngle/Features/AngleSettingView.swift`：动态背景并移除强制深色。咩
- `DuoAngle/DuoAngle/Features/SupportDevelopmentView.swift`：动态背景和文字，并移除强制深色。咩

## 编译、测试与模拟器观察

- 使用 Xcode MCP 在 iPhone Duo、iOS 27.1 上完成 Debug 构建和运行，以及 Release 构建，均成功且无编译警告或错误。咩
- Xcode MCP 完整测试通过 **11 项，失败 0 项**，其中包括 8 项单元测试和 3 项 UI 测试。咩
- 已观察 Open→Partially Open 与反向转换，并检查浅色 Open、浅色 Partially Open、深色 Partially Open 的实际界面。咩
- 深色下打开“支持开发”sheet 后切换为浅色，sheet 与主界面同步更新，角度仍显示原值且无需重启应用。咩
- 浅色下已打开“设定角度”sheet，并验证两个页面的打开与关闭。咩
- 现有单元测试覆盖关闭状态清空和测量状态行为，但连续慢速及快速折叠、精确视觉延迟、Reduce Motion 动态效果和实体设备行为尚未得到可靠验证。咩
- Device Hub 仅提供离散的 Closed、Partially Open、Open 控制，因此不能据此断言慢速或快速折叠的连续运动表现。咩

## 限制与下一阶段

- 当前公开布局信息不足以在系统选择可见区域前可靠地把读数移到某一侧，问题需随 iOS 27.1 后续 SDK 或实体 Duo 的公开行为继续验证。咩
- 实体 iPhone Duo 尚未测试，特别需要核对折叠过程中可见区域与 `reservedRegions` 时序。咩
- 外观和现有功能已可作为 Phase 4 的基础；Phase 4 不应以本阶段已解决读数迁移延迟为前提。咩
