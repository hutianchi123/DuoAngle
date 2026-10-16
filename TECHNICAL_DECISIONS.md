# Duo Angle — Phase 0 技术决策

日期：2026-10-16 咩。

状态含义：**已决定**表示具备 SDK 证据且产品约束已明确；**暂定**表示仍待模拟器或真机验证咩。证据详情及官方链接见 [API_AUDIT.md](API_AUDIT.md) 咩。

## D1 铰链 API 选择 — 暂定

- **问题**：需要持续读取真实角度，并区分闭合、部分展开、完全展开和不可用咩。
- **可用方案**：SwiftUI `onHingeChange`＋`DeviceHinge`；UIKit `UIHingeInteraction`＋`UIHinge`；Core Motion 不能直接提供物理铰链角度咩。
- **拟采用**：新测量入口优先 SwiftUI 回调，通过 `HingeMeasurementProviding` 发布独立快照；保留现有 UIKit provider 作为已编译的替代路径，待真实 Duo 测试后决定是否淘汰其一咩。
- **证据**：两套公开 API 在 iOS 27.1 SDK 均有声明且最小探针通过；苹果建议将铰链数据用于实时交互，系统控制更新频率和粒度咩。
- **权衡**：SwiftUI 少一层视图桥接，现有 UIKit provider 已存在且对层级离开时的 `nil` 有明确语义；并行保留两种生产入口会增加维护负担，所以正式实现只应选一个咩。
- **剩余风险**：真机更新间隔、端点、状态转换、闭合时上下文行为和场景切换均未测咩。

## D2 SwiftUI 与 UIKit 边界 — 已决定

- **问题**：测量层不应迫使整个界面变为 UIKit 咩。
- **可用方案**：全部 SwiftUI；SwiftUI 界面加 UIKit 铰链 bridge；UIKit 容器加 SwiftUI 子视图咩。
- **采用**：界面和区域布局优先原生 SwiftUI；仅在现有 `UIHingeInteraction` provider 或独立触觉适配器需要时使用 UIKit，并把平台类型限制在适配边界咩。
- **证据**：SwiftUI 的铰链、区域和布局 API 已编译通过；`ARCHITECTURE.md` 已有 `HingeMeasurementProviding` 和不泄露 UIKit 类型的快照边界咩。
- **权衡**：SwiftUI 方式减少桥接代码，UIKit 仍可提供明确的 view hierarchy 生命周期回调咩。
- **剩余风险**：真实场景中 SwiftUI 回调与 UIKit interaction 的差异需对照测试咩。

## D3 显示区域协调 — 暂定

- **问题**：主读数不能跨折痕或落入不适合展示的区域咩。
- **可用方案**：SwiftUI `GeometryProxy.reservedRegions(kind: .division/.occlusion)` 和标准安全区域；双内容布局的 `ArrangementView`；UIKit `UIView.reservedRegions`；根据角度硬编码左右屏咩。
- **拟采用**：普通单场景 SwiftUI 界面读取当前几何、尺寸类别、安全区域和活动 division/occlusion region，使角度读数位于当前视图内一块完整可用区域；只有实际出现两个语义内容区时才考虑 `ArrangementView` 咩。
- **证据**：SDK 区域查询和 `ArrangementView` 探针通过；苹果技术讲座确认折叠分隔区域为 division region，并建议用区域布局 API 而非铰链角度做布局决策咩。
- **权衡**：布局交给系统可随旋转、内外屏尺寸变化适配；区域几何没有承诺返回“用户正在观看的物理面板”咩。
- **剩余风险**：部分折叠时哪个区域真正清晰可见、场景从内屏到外屏如何迁移，必须真机观察；不能承诺任何固定面板咩。

## D4 系统模糊处理 — 已决定的约束，运行效果待验证

- **问题**：用户需求要求避免主读数被系统管理的模糊或无效显示覆盖咩。
- **可用方案**：公开 reserved-region 与标准容器自适应；系统管理场景；私有模糊开关或运行时修改咩。
- **采用**：只使用公开布局信息和系统场景行为；不尝试关闭或覆盖系统模糊咩。
- **证据**：所查 iOS 27.1 公开 SDK、苹果 Duo 设计指南和技术讲座均未提供可关闭系统模糊或读取整块面板模糊状态的第三方 API咩。
- **权衡**：符合平台支持范围；仅靠 API 静态信息无法证明读数始终清晰咩。
- **剩余风险**：需求中的“模糊或无效面板”具体触发条件与可观测信号仍待真机确认；若系统行为无法满足始终可见，应按实测对 R-004 给出最小修订咩。

## D5 触觉反馈 — 暂定

- **问题**：多个目标角度需要一次短促触觉，不能在阈值附近反复触发咩。
- **可用方案**：SwiftUI `sensoryFeedback`；UIKit `UIImpactFeedbackGenerator`；Core Haptics 自定义模式咩。
- **拟采用**：目标监测器发离散事件，独立 `HapticManager` 使用轻量 `UIImpactFeedbackGenerator` 发短促反馈，同时由界面显示等价的目标到达状态咩。
- **证据**：反馈生成器探针通过，苹果触觉指南建议短促、可关闭且有视觉配合的反馈；Core Haptics 面向自定义波形咩。
- **权衡**：UIKit 调用比纯 SwiftUI 多一个小适配器，却便于由与视图无关的目标监测器主动触发；`prepare()` 可在预计即将触发时降低延迟，但不能保证即时响应咩。
- **剩余风险**：Duo 真机振感、系统触觉设置、前后台限制和最佳容差未测；必须采用容差、滞回、每目标重新武装，并允许从两个方向进入目标咩。

## D6 自愿一次性支持购买 — 暂定

- **问题**：支持开发只能购买一次，核心测量始终免费，价格期望约 ¥5 咩。
- **可用方案**：non-consumable 一次买断；consumable 可重复打赏；订阅与需求不符咩。
- **拟采用**：StoreKit 2 `nonConsumable` 产品，加载 App Store Connect 实际商品并显示 `displayPrice`；核验交易后 `finish()`，启动时读权益并提供用户主动恢复入口咩。
- **证据**：StoreKit 2 探针通过，苹果定义 non-consumable 为购买一次且不会耗尽；`PurchaseResult`、`Transaction.updates`、`AppStore.sync()` 均有公开文档咩。
- **权衡**：天然限制重复购买并可恢复；“不解锁功能的支持商品”需在商品描述和审核备注中说明，且 exact ¥5 价格点未经 App Store Connect 核实咩。
- **剩余风险**：商品标识、销售地区、价格点、协议和 App Review 结果均未配置或验证；正式交易和本地 `.storekit` 交易均留待后续阶段咩。

## D7 最低部署目标 — 已决定

- **问题**：本次审计开始时工程实际为 iOS 27.0，而关键铰链和区域 API 从 iOS 27.1 才有咩。
- **可用方案**：保留 27.0 并加可用性守卫、在旧系统显示不支持；统一升至 27.1 咩。
- **采用**：按用户本次明确指示，将项目、应用、单元测试和 UI 测试相关 `IPHONEOS_DEPLOYMENT_TARGET` 全部设为 27.1 咩。
- **证据**：SDK 声明及 27.0 目标探针报错确认最小版本；本机 Xcode 27.1 提供所需 iOS 27.1 SDK咩。
- **权衡**：去除无测量能力的旧系统兼容分支；运行要求提高到 iOS 27.1咩。
- **剩余风险**：其他开发机和 CI 必须安装相应 SDK；这不解决无 Duo 铰链硬件的设备支持问题咩。

## 建议的最小组件边界

`HingeMeasurementProviding` 保持协议，用于真实数据提供者与显式 Mock；`HingeMeasurementManager` 负责启停和将回调转成 `HingeMeasurementSnapshot`，快照保留原始角度、系统状态、可用性及必要的更新时间，不在 UI 层推断硬件状态咩。现有 Phase 0.5 类型可沿用，但其 UIKit provider 与拟采用的 SwiftUI 入口应通过真机比较后只保留一个正式路径咩。

`DuoDisplayManager` 宜缩减为“当前视图可用几何”的纯布局决策，不宣称知道左屏、右屏、模糊开关或主可见物理屏；活跃 scene 协调只监听公开 scene phase、尺寸与窗口层级变化，确有真机需求再引入独立协调器咩。`TargetMonitor` 单独处理多个目标及滞回；`HapticManager` 只接收离散事件；`SupportProductManager` 完全独立于测量启动路径咩。

Phase 0 不实现上述组件，不进入 Phase 1 咩。
