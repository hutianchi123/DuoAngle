# Duo Angle — Phase 0 平台与 API 审计

审计日期：2026-10-16 咩。

## 1. 执行摘要

公开的 SwiftUI `DeviceHinge`、`DeviceHingeContext` 与 `onHingeChange(isEnabled:_:)` 已在本机 iOS 27.1 SDK 中确认并通过最小类型检查，能获取系统提供的铰链角度与状态，苹果将该数据称为实时观察数据咩。角度更新频率、粒度、物理端点与真机准确度没有保证，且本次没有 iPhone Duo 真机测量结果咩。

折叠布局可使用 SwiftUI `ReservedRegion`、`GeometryProxy.reservedRegions(...)` 和 `ArrangementView`，系统提供折叠分隔区域及常规安全区域、尺寸类别和场景布局机制咩。这些 API 没有提供“当前可见物理面板”或“系统模糊状态”的直接枚举，因此现阶段不能保证主读数在所有折叠过渡中始终位于未模糊的面板咩。未验证到可供第三方关闭系统管理模糊的公开 API，后续须采用自适应布局并在真机检验咩。

本次是 Phase 0 审计，没有修改应用功能源码、付款配置或生产购买流程；根据用户在审计期间的明确决定，应用及测试 target 的最低部署目标统一调整为 iOS 27.1 咩。

## 2. 开发环境与仓库现状

| 项目 | 本次观察 |
|---|---|
| macOS | 27.0.1，Build 26A434 |
| 活跃 Xcode | 27.1，Build 27A9275 |
| Developer Directory | `/Applications/Xcode.app/Contents/Developer` |
| Swift | Apple Swift 6.4，swiftlang-6.4.0.34.1，clang-2100.3.34.1 |
| iOS SDK | iPhoneOS 27.1；iPhoneSimulator 27.1 |
| Simulator runtimes | iOS 27.0 (24A434)；iOS 27.1 (24A94425) |
| 模拟设备 | iPhone Duo / iOS 27.1，已启动；iPhone 18 Pro / iOS 27.0，已关机 |
| 物理设备 | 已配对 iPad Pro 11 英寸第三代、Apple Watch Series 11；iPhone 14 Pro 显示不可用；没有 iPhone Duo 真机 |
| 工程部署目标 | 审计开始时主应用、单元测试、UI 测试为 iOS 27.0；按用户本次决定现均为 iOS 27.1；`SWIFT_VERSION = 5.0`；设备族为 iPhone 和 iPad |
| Xcode MCP | 当前会话没有暴露 XcodeBuildMCP 工具；使用本机 `xcodebuild`、`swiftc`、`simctl` 和 Device Hub 核验 |
| Git | 审计开始时根目录不是 Git 仓库；为按要求提交 Phase 0，本次在根目录初始化本地仓库；没有配置 remote |

通过 `sw_vers`、`xcode-select -p`、`xcodebuild -version/-showsdks`、`xcrun swift --version`、`xcrun simctl list`、`xcrun devicectl list devices` 与工程 `project.pbxproj` 取得上述值咩。第一次在受限终端查询 `simctl` 因 CoreSimulatorService 连接失败，获准在沙盒外重试后正常列出运行时与已启动的 Duo 模拟器，因此它不是当前安装缺失的证据咩。若在其他机器缺少 iOS 27.1 SDK 或 Duo 模拟器，需从 Xcode 的平台组件安装 iOS 27.1 并在 Device Hub 添加 Duo 模拟设备；本机无需安装咩。

苹果资料和本机 SDK 均指向最低 iOS 27.1；本机具备 Xcode 27.1，未证明更早 Xcode 包含这些 API 咩。[苹果 Duo 准备指南](https://developer.apple.com/videos/play/tech-talks/111461/)咩。

## 3. 证据分级与 API 表

“SDK 声明＋编译通过”只证明符号与探针代码可类型检查，不证明运行时、模拟器传感器或真机行为咩。“模拟器观察”仅指 Device Hub 的界面姿态切换咩。

| API | Module | Availability | Evidence | Verification status | Notes |
|---|---|---|---|---|---|
| `DeviceHinge.angle/status` | SwiftUI（声明位于 SwiftUICore） | iOS 27.1+ | SDK 接口；[Apple](https://developer.apple.com/documentation/swiftui/devicehinge)；探针 P1 | SDK 声明＋编译通过 | `angle: Angle`；SwiftUI 状态公开 closed/partiallyOpen/fullyOpen |
| `DeviceHingeContext.hinge` | SwiftUI（SwiftUICore） | iOS 27.1+ | SDK 接口；探针 P1 | SDK 声明＋编译通过 | `DeviceHinge?`，`nil` 表示当前层级没有铰链上下文 |
| `View.onHingeChange(isEnabled:_:)` | SwiftUI（SwiftUICore） | iOS 27.1+ | SDK 接口；[Apple](https://developer.apple.com/documentation/swiftui/view/onhingechange%28isenabled%3A_%3A%29)；P1 | SDK 声明＋编译通过 | 旧、新上下文回调；实际更新速率未测 |
| `UIHinge.angle/status` | UIKit | iOS 27.1+ | `UIHinge.h`；[Apple](https://developer.apple.com/documentation/uikit/uihinge)；P2 | SDK 声明＋编译通过 | `CGFloat` 弧度；UIKit 另有 `.unknown` |
| `UIHingeInteraction` / `Update.hinge` | UIKit | iOS 27.1+ | `UIHingeInteraction.h`；[Apple](https://developer.apple.com/documentation/uikit/uihingeinteraction)；P2 | SDK 声明＋编译通过 | 绑定 `UIView`，初始及变化回调；离开可提供铰链的层级时为 `nil` |
| `ReservedRegion` / `GeometryProxy.reservedRegions(...)` | SwiftUI（SwiftUICore） | iOS 27.1+ | SDK 接口；[Apple](https://developer.apple.com/documentation/swiftui/geometryproxy)；P3 | SDK 声明＋编译通过 | `.division`/`.occlusion`，`frame`、`margins`、`isActive`、`includeInactive` |
| `UIView.ReservedRegion` / `reservedRegions(kind:options:)` | UIKit | iOS 27.1+ | `UIViewReservedRegion.h`、`UIView.h`；[Apple](https://developer.apple.com/documentation/uikit/uiview/reservedregion) | SDK 声明＋文档核实 | 此次未单独编译 UIKit 布局探针 |
| `ArrangementView(primary:secondary:)` / `.arrangementViewStyle(.split)` | SwiftUI（SwiftUICore） | iOS 27.1+ | SDK 接口；[Apple 技术讲座](https://developer.apple.com/videos/play/tech-talks/111463/)；P3 | SDK 声明＋编译通过 | 适合两个内容区；不等于可见面板选择器 |
| `UIArrangementViewController` | UIKit | iOS 27.1+ | `UIArrangementViewController.h`；[Apple 技术讲座](https://developer.apple.com/videos/play/tech-talks/111463/) | SDK 声明＋文档核实 | 当前 SwiftUI 产品无采用理由 |
| `CameraCaptureAccessory` | SwiftUI | iOS 27.1+ | SDK 接口；[Apple 场景讲座](https://developer.apple.com/videos/play/tech-talks/111464/) | SDK 声明＋文档核实 | 需前台、内屏全屏及活跃相机；不适用于测角常规双屏路由 |
| `UIImpactFeedbackGenerator` | UIKit | iOS 10+ | SDK 头文件；[Apple](https://developer.apple.com/documentation/uikit/uiimpactfeedbackgenerator/impactoccurred%28%29)；P4 | SDK 声明＋编译通过 | 需真机确认实际触觉 |
| `View.sensoryFeedback` | SwiftUI | iOS 17+ | [Apple](https://developer.apple.com/documentation/swiftui/view/sensoryfeedback%28trigger%3A_%3A%29) | 文档核实 | 可由离散事件 token 触发；本次未编译 |
| `Product` / `purchase()` / `Transaction` | StoreKit | iOS 15+ | SDK 接口；[Apple](https://developer.apple.com/documentation/storekit/choosing-a-storekit-api-for-in-app-purchases)；P4 | SDK 声明＋编译通过 | 未运行交易 |
| 系统模糊关闭或可见物理面板 API | 未发现 | 未确认 | 搜索公开 SDK 声明和下列苹果 Duo 文档 | 未验证存在 | 仅能作有范围的“未发现”结论 |

SDK 定位：`iPhoneOS27.1.sdk/System/Library/Frameworks/SwiftUICore.framework/Modules/SwiftUICore.swiftmodule/arm64e-apple-ios.swiftinterface` 约 4842、10289、16652、16740、24265 行；UIKit 对应 `Headers/UIHinge.h`、`UIHingeInteraction.h`、`UIViewReservedRegion.h`、`UIView.h`、`UIArrangementViewController.h` 咩。

布局候选的精确 Swift 声明要点如下；`SceneAccessory` 入口的 `View.sceneAccessory(content:)` 在 SDK 标为 iOS 27.0+，具体 `CameraCaptureAccessory` 标为 iOS 27.1+，二者不能混为一谈咩。

```swift
@available(anyAppleOS 27.1, *)
struct ReservedRegion {
    var frame: CGRect { get }
    var margins: EdgeInsets { get }
    var isActive: Bool { get }
}
@available(anyAppleOS 27.1, *)
extension GeometryProxy {
    func reservedRegions(kind: ReservedRegion.Kind,
        options: ReservedRegion.QueryOptions = [],
        layoutDirectionBehavior: LayoutDirectionBehavior = .mirrors) -> [ReservedRegion]
}
@available(anyAppleOS 27.1, *)
struct ArrangementView<Primary: View, Secondary: View>: View {
    init(@ViewBuilder primary: () -> Primary, @ViewBuilder secondary: () -> Secondary)
}
```

## 4. 铰链测量与生命周期

本机 SDK 的关键 Swift 声明如下，应用代码通过 `import SwiftUI` 使用这些公开类型咩。

```swift
@available(anyAppleOS 27.1, *)
struct DeviceHinge { var status: DeviceHinge.Status; var angle: Angle }
@available(anyAppleOS 27.1, *)
struct DeviceHingeContext { var hinge: DeviceHinge? }
@available(anyAppleOS 27.1, *)
extension View {
    func onHingeChange(isEnabled: Bool = true,
        _ action: @escaping (DeviceHingeContext, DeviceHingeContext) -> Void) -> some View
}
```

`DeviceHinge.Status` 在公开 Swift 接口中提供 `.closed`、`.partiallyOpen`、`.fullyOpen`，没有公开的 `.unknown` 静态成员；`nil` 的上下文需单独表示 unavailable/unsupported，不能把它误读为 closed 咩。`Angle` 可转换为度数用于显示，但 SDK 没有给出保证的物理范围或端点对应角度咩。[DeviceHinge 文档](https://developer.apple.com/documentation/swiftui/devicehinge)咩。

UIKit 的替代路径为 `UIHinge.angle: CGFloat`（弧度）、`UIHinge.status: UIHinge.Status`（`.unknown`、`.closed`、`.partiallyOpen`、`.fullyOpen`），以及 `UIHingeInteraction(updateHandler:)` 的 `Update.hinge: UIHinge?` 咩。UIKit 头文件明确写明回调会给初始状态，铰链变化或交互对象跨层级时继续回调；禁用时不排队更新，重新启用后在可用时给当前状态；处理器会被持有，需避免引用环咩。SwiftUI 回调使用视图层级上下文，也应在视图消失、场景转后台与返回前台时避免保留旧角度；具体生命周期时序待模拟器和真机验证咩。[UIHingeInteraction 文档](https://developer.apple.com/documentation/uikit/uihingeinteraction)咩。

苹果明确称铰链数据可实时观察，适合驱动交互效果；系统控制更新速率和角度粒度，不能由公开资料推断固定帧率、精度或每一度都会回调咩。状态应直接用于 closed/partially open/fully open 语义，不能发明状态阈值；目标角度容差属于独立产品逻辑咩。[苹果多屏讲座](https://developer.apple.com/videos/play/tech-talks/111464/)；本机 `UIHinge.h` 咩。

## 5. 折叠、显示区域与模糊

iPhone Duo 有内外显示区域；闭合时用户使用外屏，内屏部分折叠时铰链形成 `.division` reserved region，系统组件可依此布局咩。[苹果设计指南](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo)；[自适应布局讲座](https://developer.apple.com/videos/play/tech-talks/111463/)咩。`GeometryProxy.reservedRegions(kind: .division)` 默认返回活动区域，`.includeInactive` 可一并获取非活动区域；苹果说明 Duo 展平时分隔区为非活动且宽度为零咩。`.occlusion` 表示摄像头等遮挡，不是“整个面板模糊”的标记咩。

`ArrangementView` 根据尺寸、朝向与 reserved regions 排列 primary/secondary 内容，适合已有双区内容；主界面仅一个角度读数时，更小的方案是保留标准 SwiftUI 场景、尺寸类别和安全区域，并用 `.division` 的实时几何为读数选择不跨折痕的布局位置咩。布局选择不能由角度阈值推断左右面板，也不能假定某一物理面板永久点亮咩。旋转可改变布局分割轴与可用空间，应按当下几何重算；模拟器目前只观察到主屏姿态切换，未执行应用内布局测试咩。[自适应布局讲座](https://developer.apple.com/videos/play/tech-talks/111463/)咩。

苹果确认 Duo 支持同一应用多个场景，外屏不能创建新的应用窗口，而内屏可创建；普通测角界面没有必要主动创建第二场景咩。`CameraCaptureAccessory` 可在满足活跃相机等条件时提供外屏附属内容，与本应用常规需求不符咩。[多屏与场景讲座](https://developer.apple.com/videos/play/tech-talks/111464/)咩。

**系统模糊调查范围**：检索了本机 iOS 27.1 公开 SwiftUI/SwiftUICore/UIKit 声明、Apple SwiftUI 与 UIKit 更新、Duo 设计指南及两场 Duo 技术讲座，未找到第三方可读取系统模糊开关、确定“主可见物理面板”或关闭系统管理模糊的公开 API 咩。`View.blur(radius:)` 仅控制应用自身视图效果，不能据此推断可覆盖系统模糊咩。因此应避开活动分隔和遮挡区域、使用系统布局容器，并以真机实际可读性作为最终验收；“某一面板折叠时被系统模糊”的具体时机尚无本次实测咩。

## 6. 模拟器、硬件、触觉与 StoreKit

Device Hub 中已实际点击 Duo 的 Closed、Partially Open、Open 控件，分别观察到外屏、部分展开和内屏主屏画面切换咩。这只验证了模拟姿态控制与显示画面，不验证应用内场景迁移、折痕 reserved region 数值、模拟铰链回调、连续角度、模糊层或物理准确度咩。界面未显示可输入任意角度的控件；本次不能确认该能力是否存在于其他控制路径咩。[Device Hub 文档](https://developer.apple.com/documentation/xcode/device-hub)；[Duo 准备讲座](https://developer.apple.com/videos/play/tech-talks/111461/)咩。

轻量目标提醒可用 UIKit `UIImpactFeedbackGenerator(style: .light)`、`prepare()`、`impactOccurred()`；该类 iOS 10 起公开，本机 SDK 的 `init(style:view:)` 从 iOS 17.5 可用，旧 `init(style:)` 仍可编译但头文件标为未来弃用方向咩。SwiftUI `sensoryFeedback` 是另一种视图驱动选择，Core Haptics 适合自定义波形但对本工具过重咩。触觉应只在目标监测器发出离散“进入目标容差”事件时触发，需容差、滞回、逐目标重新武装，并支持任意方向及前后台暂停；不得把每次角度回调都转换成振动咩。苹果说明部分设备无触觉，模拟器没有触觉接口，视觉/辅助技术反馈必须同时存在，用户应可关闭提醒咩。[触觉设计指南](https://developer.apple.com/design/human-interface-guidelines/playing-haptics)；[Core Haptics 设备能力](https://developer.apple.com/documentation/corehaptics/preparing-your-app-to-play-haptics)；[模拟器限制](https://developer.apple.com/documentation/corehaptics/playing-a-custom-haptic-pattern-from-a-file)咩。

StoreKit 2 的 Swift API 从 iOS 15 可用咩。按照“仅能自愿支持一次”的需求，提议 `Product.ProductType.nonConsumable`，而 consumable 更适合可重复打赏；前者可在重装后识别和恢复，但无功能解锁的产品审核解释仍需明确咩。[商品类型](https://developer.apple.com/help/app-store-connect/configure-in-app-purchase-settings/overview-for-configuring-in-app-purchases/)；[审核准则 3.1.1](https://developer.apple.com/app-store/review/guidelines/)咩。未来需在 App Store Connect 创建与代码一致的唯一 product ID、商品元数据、销售地区及价格，接受 Paid Apps Agreement，界面读取 `Product.displayPrice`，而非写死 ¥5；账户未接入，本次没有核实中国区是否可选精确 ¥5 咩。[价格设置](https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/set-a-price-for-an-in-app-purchase)咩。

购买返回 `.success(VerificationResult<Transaction>)`、`.pending`、`.userCancelled` 或抛错；成功时先核验再 `finish()`，未核验交易不标为成功；应用另观察 `Transaction.updates` 并读取当前权益咩。[PurchaseResult](https://developer.apple.com/documentation/storekit/product/purchaseresult)；[当前权益](https://developer.apple.com/documentation/storekit/transaction/currententitlements)咩。可提供用户主动触发的 Restore，常规启动先读权益，只有用户操作时调用 `AppStore.sync()`，它可能要求认证咩。[AppStore.sync](https://developer.apple.com/documentation/storekit/appstore/sync%28%29)咩。本地 `.storekit` 配置可在无生产付款时测试商品、取消、待处理与恢复；本阶段只核实能力，没有创建配置或执行交易咩。[本地 StoreKit 测试](https://developer.apple.com/documentation/xcode/setting-up-storekit-testing-in-xcode)咩。

## 7. 最小编译实验

所有探针曾位于 `/private/tmp/duoangle-phase0-probes`，核验后已清理，不属于产品源码；命令使用 Xcode 27.1 的 Swift 6.4 和 `iPhoneOS27.1.sdk`，目标 `arm64-apple-ios27.1`，调用形式为 `xcrun swiftc -typecheck -module-cache-path /private/tmp/duoangle-phase0-probes/cache -target arm64-apple-ios27.1 -sdk <iPhoneOS27.1.sdk> <probe.swift>` 咩。

| 探针 | 测试路径 | 结果 | 诊断与解释 |
|---|---|---|---|
| P1 `HingeSwiftUI.swift` | `DeviceHinge`、`Angle.degrees`、状态、`onHingeChange` | 通过 | 无诊断；仅类型检查 |
| P2 `HingeUIKit.swift` | `UIHingeInteraction`、可选 update.hinge、angle/status、`UIView.addInteraction` | 通过 | 无诊断；仅类型检查 |
| P3 `LayoutSwiftUI.swift` | `ArrangementView`、`.split`、`.division/.occlusion` 与 `.includeInactive` | 通过 | 无诊断；仅类型检查 |
| P4 `Ancillary.swift` | UIKit 反馈生成器；StoreKit 加载、价格、nonConsumable、购买结果和 `finish()` | 通过 | 无诊断；未运行触觉或购买 |
| P1 改用 iOS 27.0 目标 | 同 P1 | 预期失败 | `'DeviceHinge' is only available in iOS 27.1 or newer`；`'onHingeChange(isEnabled:_:)' is only available in iOS 27.1 or newer` |

首次类型检查因默认模块缓存路径 `/Users/huyajun/.cache/clang/ModuleCache` 无写权限失败，属于环境错误咩。改用临时缓存后，包含 `@State` 的初稿因沙盒内 `swift-plugin-server` 返回 malformed response 而失败，属于宏插件执行环境错误；将状态存储从纯 API 探针去掉后 P1–P4 均通过，没有把前两次失败解读成 API 不存在咩。探针源码不是完整应用，也不能证明回调实际产生咩。

## 8. 官方资料索引

- [SwiftUI `DeviceHinge`](https://developer.apple.com/documentation/swiftui/devicehinge) 与 [`onHingeChange`](https://developer.apple.com/documentation/swiftui/view/onhingechange%28isenabled%3A_%3A%29) 咩。
- [UIKit `UIHinge`](https://developer.apple.com/documentation/uikit/uihinge) 与 [`UIHingeInteraction`](https://developer.apple.com/documentation/uikit/uihingeinteraction) 咩。
- [SwiftUI `GeometryProxy` 的 reserved regions](https://developer.apple.com/documentation/swiftui/geometryproxy) 与 [UIKit `UIView.ReservedRegion`](https://developer.apple.com/documentation/uikit/uiview/reservedregion) 咩。
- [苹果 iPhone Duo 设计指南](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo)、[自适应布局讲座](https://developer.apple.com/videos/play/tech-talks/111463/) 与 [多屏场景讲座](https://developer.apple.com/videos/play/tech-talks/111464/) 咩。
- [Device Hub](https://developer.apple.com/documentation/xcode/device-hub) 与 [Duo 模拟器准备](https://developer.apple.com/videos/play/tech-talks/111461/) 咩。
- [UIKit 触觉](https://developer.apple.com/documentation/uikit/uiimpactfeedbackgenerator/impactoccurred%28%29) 与 [触觉设计指南](https://developer.apple.com/design/human-interface-guidelines/playing-haptics) 咩。
- [StoreKit 2 选择](https://developer.apple.com/documentation/storekit/choosing-a-storekit-api-for-in-app-purchases)、[购买结果](https://developer.apple.com/documentation/storekit/product/purchaseresult)、[本地测试](https://developer.apple.com/documentation/xcode/setting-up-storekit-testing-in-xcode) 与 [价格配置](https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/set-a-price-for-an-in-app-purchase) 咩。

## 9. 未解决问题、文档矛盾与 Phase 0 结论

1. 真机需验证角度物理语义、端点、噪声、延迟、回调间隔、closed 时的上下文和状态转换；不能把模拟器值当成物理验证咩。
2. 真机需验证内外屏切换、不同朝向、场景前后台、系统模糊或不可用区域、标准容器与自定义读数的实际可见性咩。
3. Device Hub 可切换三种姿态，但模拟角度是否连续变化和能否精确设值尚未通过应用回调观察咩。
4. `Documentation/IMPLEMENTATION_PLAN.md` 与 `Documentation/PHASE_0_AUDIT.md` 记载 SwiftUI 铰链和 Duo reserved-region API 尚未确认、Simulator 服务不可用，而本次 iOS 27.1 SDK、官方新资料和 Device Hub 观察推翻这些旧环境结论；原文件未被静默改写咩。
5. `Documentation/PHASE_0_5_REPORT.md` 记载部署目标已升 iOS 27.1，但本次审计开始时 `project.pbxproj` 三个 target 实际仍为 27.0；用户随后明确要求全部采用 27.1，本次已将工程的四处配置（含项目级配置）统一更新，历史报告未被静默改写咩。
6. 既有 Phase 0.5 源码已有 `MainView` 壳和 Mock provider，本次没有实现或扩展这些界面；它们的存在不构成本次真实设备验证咩。

**Phase 0 readiness：READY WITH RISKS** 咩。公开、可编译的测量及折叠布局 API 已找到，部署目标也已统一为 iOS 27.1；“全折叠过程中始终显示于合适可见区域”仍未证实，进入任何产品化阶段前必须在真实 Duo 上通过该验收咩。
