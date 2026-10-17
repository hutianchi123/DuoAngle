# Duo Angle — Phase 3 主界面与导航报告

日期：2026-10-17 咩。

## 实现摘要

- `MainView` 保留 Phase 1 的 `HingeMeasurementManager` 与 `onHingeChange` 管线，保留 Phase 2 的 `DuoDisplayManager` 单一读数布局咩。
- 新增窗口相对的 `.safeAreaInset(edge: .bottom)` 操作栏，两个按钮不在 `ArrangementView` 内，因此读数位置变化时按钮仍固定在底部安全区域咩。
- `BottomActionBar` 使用系统 `.glass` 按钮样式、`Label` 和 SF Symbols 的 `angle`、`heart`，狭窄宽度由 `ViewThatFits` 切换为纵向排列咩。
- `MainView` 用单个可选目的地状态及 `.sheet(item:)` 打开“设定角度”和“支持开发”，两个页面均有“完成”按钮和系统交互式关闭能力咩。
- 设定页面仅显示“暂无目标角度”，支持页面仅显示说明文案，未加入目标持久化、监控或购买功能咩。

## 数值动画与辅助功能

- 可用角度的格式化文本使用 `.contentTransition(.numericText())` 和 0.1 秒线性动画，测量原始弧度、时间戳及管理器发布流程未改变咩。
- 动画只以 `displayText` 为变化值；未变化的整数读数不触发新动画，短时长使新值能够迅速替换前一次过渡咩。
- `accessibilityReduceMotion` 为真或读数不可用时使用 `.identity` 过渡并取消显式动画咩。
- 读数保持 `.monospacedDigit()`、居中布局和可缩小字号，VoiceOver 使用“当前角度，128 度”形式的整体标签，按钮有明确中文标签和至少 44 点高度咩。
- DEBUG 诊断继续由条件编译控制，Release 构建不包含诊断入口咩。

## 文件

- 修改：`DuoAngle/DuoAngle/Features/MainView.swift`、`DuoAngle/DuoAngleUITests/DuoAngleUITests.swift` 咩。
- 新增：`DuoAngle/DuoAngle/Components/BottomActionBar.swift`、`DuoAngle/DuoAngle/Features/AngleSettingView.swift`、`DuoAngle/DuoAngle/Features/SupportDevelopmentView.swift`、本报告咩。

## 构建、测试与模拟器观察

- XcodeBuildMCP 在 iPhone Duo / iOS 27.1 模拟器上完成 Debug 构建和启动，Release 模拟器构建成功，构建诊断中没有警告或错误咩。
- 完整测试套件为 11 通过、0 失败、0 跳过，包含原有 8 个单元测试、原有 2 个 UI 测试及新增的双页面导航 UI 测试咩。
- 首次新增 UI 测试在实现前按预期因缺少按钮失败；实现后第一次运行时，Duo 测试克隆模拟器的初次点击没有打开 Sheet，测试加入启动期间一次重试后单测及完整套件均通过咩。
- Closed 截图显示展开提示、黑底、两个底部按钮和 DEBUG 诊断入口，没有旧角度咩。
- Partially Open 截图显示右侧区域的单一 `127°` 读数，按钮仍靠窗口底部排列，没有随读数移到右侧中央咩。
- Open 截图显示单一 `180°` 读数居中，按钮仍靠窗口底部咩。
- 两个 Sheet 均通过 XcodeBuildMCP 的界面快照和手动点击验证打开，“完成”能返回主界面；系统交互式下滑关闭未单独执行咩。
- `angle` 与 `heart` 图标均在模拟器截图中正常显示咩。

## 限制与 Phase 4 准备

- Device Hub 仅提供离散姿态，未能以连续角度检查数值滚动在慢速及高频更新时的观感或延迟咩。
- Reduce Motion 的代码路径已经接入，但本次没有单独切换系统设置做运行时观感检查咩。
- 没有实体 iPhone Duo，物理折叠可见性、系统模糊、触觉和角度准确度仍待真机验证咩。
- 本阶段未使用私有 API、角度阈值或虚构测量值，Phase 4 可在现有 Sheet 中加入真实目标管理功能咩。
