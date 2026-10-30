# Phase 9 完成报告

## Phase 9.2 — 实体 iPhone 兼容性识别

- 根因是应用实际 `@main` 入口 `DuoAngleApp` 仍把 `.unknown` 送入 `MainView`；仅修改 `ContentView` 不会影响应用启动路由咩。
- 通过公开 POSIX `sysctlbyname("hw.machine")` 读取实体硬件型号；连接中的实体 iPhone 14 Pro 经 Xcode 设备列表确认为 `iPhone15,2`，该标识未列入经实体验证的 Duo 支持清单，因此判为不支持咩。
- iPad 继续通过 `userInterfaceIdiom == .pad` 识别为不支持；凡成功读取到型号标识但未列入实体 iPhone Duo 支持清单的设备均为 `.unsupported`，不显示角度测量操作；只有机型标识读取失败才保留 `.unknown` 中性页咩。
- 模拟器只读取 `SIMULATOR_MODEL_IDENTIFIER`；连接的 iPhone Duo 模拟器产品标识为 `iPhone19,4`，该值仅用于模拟器测量通路，不作为实体 Duo 硬件标识咩。
- 支持的物理 Duo 标识尚未从实体设备核实；当前实体 iPhone 支持清单为空，因此已识别的实体 Duo 也会落入 `.unsupported`，直到读取并登记真实 `hw.machine`；这是发布阻塞项，不能宣称实体 Duo 已支持咩。
- XcodeBuildMCP 定向验证共 10 项通过：6 项 `DeviceCapabilityTests` 加 4 项兼容性 UI 测试，覆盖实体 iPhone 14 Pro 标识、未登记机型、缺失标识、iPad、Duo 模拟器、暂时无铰链样本、未知中性页及不支持页操作咩。
- iPhone Duo 模拟器无覆盖运行时保留测量界面并显示 `180°`；本轮 Debug 和 Release 验证后均未关闭模拟器咩。
- 本次未在实体 iPhone 14 Pro 上安装 Release 包验证屏幕；硬件型号已从当前连接的设备清单读取，但 Xcode MCP 物理设备交互不可用咩。
- Apple 发布新 iPhone Duo 后，先从实体设备读取 `hw.machine` 并核实零售型号，再将该标识加入物理支持清单；其他可识别机型依照当前产品规则归为不支持，只有系统无法读取型号时进入中性未确认页咩。
- XcodeBuildMCP 的 Release 模拟器构建成功；未登记为 Duo 的 Release iPhone 18 Pro 模拟器启动后显示不支持页，且无测量入口咩。
- 无签名 iOS Release 设备目标构建成功，已编译到真实设备专用的 `sysctlbyname` 分支；该构建未安装到实体手机咩。
- Release 包 `CFBundleIdentifier` 仍为 `com.hutianchi123.DuoAngle`，可执行文件未包含 `FOLDMETRY_DEVICE_CAPABILITY` 或 `foldmetry-device-capability` Debug 覆盖标记；StoreKit 配置文件未由本次改动触碰咩。

## 修复内容

- 将应用默认显示名称设为 `FoldMetry`，并为 `zh-Hans`、`zh-Hant`、`en`、`ja`、`ko` 编译 `InfoPlist.strings` 本地化资源；简体与繁体中文显示“有度”，英文、日文、韩文显示“FoldMetry”咩。
- Xcode 的文件系统同步目录已将五份 `InfoPlist.strings` 纳入 App target；Debug 与 Release 生成的 `Info.plist` 默认 `CFBundleDisplayName` 均为 `FoldMetry`咩。
- `DeviceCapabilityResolver` 先检查公开 UIKit 接口 `UIDevice.current.userInterfaceIdiom == .pad`，并将所有 iPad 解析为 `.unsupported`；iPhone 没有能力信号时仍解析为 `.unknown`咩。
- DEBUG 构建继续接受 `-foldmetry-device-capability` 和 `FOLDMETRY_DEVICE_CAPABILITY`，可强制 `supported`、`unsupported`、`unknown`；Release 可执行文件不含这两个覆盖标记咩。
- 不支持设备页采用可滚动内容和底部安全区操作区；“了解 iPhone Duo”使用高对比度主按钮和系统 `openURL`，底部继续打开既有 `SupportDevelopmentView`咩。
- Apple 信息入口使用已核实的官方页面 `https://www.apple.com/iphone/`，页面含 iPhone Duo 产品入口；应用内没有第三方商店或微信支付入口咩。

## 验证结果

- XcodeBuildMCP 在 iPhone 18 Pro / iOS 27.2、iPad mini / iOS 27.2、iPhone Duo / iOS 27.1 上完成 Debug 构建和启动；Release 模拟器构建通过咩。
- `DeviceCapabilityTests` 的 2 项定向单测通过，覆盖 iPad 为 `.unsupported` 和普通 iPhone 无能力信号时保持 `.unknown`咩。
- iPhone 18 Pro 的中文主屏幕辅助功能快照显示应用图标名称“有度”；中文不支持页展示标题、说明、Apple 主按钮和“支持开发”咩。
- iPhone 18 Pro 以英文启动参数运行时，界面快照显示英文不支持说明、`Explore iPhone Duo` 和 `Support Development`；Release 包内英文 `InfoPlist.strings` 值为 `FoldMetry`咩。
- iPad mini 无覆盖启动时进入 `UnsupportedDeviceView`；界面无测量读数、角度设置或测量操作，浅色和深色截图都能看到 Apple 主按钮及底部支持入口咩。
- 点击 Apple 主按钮后，iPhone 18 Pro 的 Safari 地址栏接收 `apple.com`，外链由系统打开咩。
- 点击“支持开发”后，实际支持页显示原 StoreKit 支持购买按钮（本地 StoreKit 配置价格 `$0.99`）、GitHub 和开发者邮箱；点击“完成”返回不支持页咩。
- iPhone Duo 无覆盖启动后仍显示测量界面，快照读数为 `180°`；iPhone 18 Pro 的默认未知能力路径保留“角度暂不可用”和测量入口咩。
- Release 产物的 `CFBundleIdentifier` 仍为 `com.hutianchi123.DuoAngle`，默认显示名为 `FoldMetry`，且未发现 DEBUG 覆盖标记咩。

## 检测限制

- 当前公开铰链 API 提供测量值，不提供可靠的设备硬件能力查询；生产环境无法仅用文档化 API 可靠区分不支持的普通 iPhone 与支持的 iPhone Duo 咩。
- 因此 iPhone 缺少铰链样本时仍显示测量界面中的暂不可用状态，不会被误判为不支持；iPad 则由公开 interface idiom 明确拦截咩。
- 已验证英文本地化资源和英文应用界面，但本次未将模拟器的系统首选语言切换为英文来观察英文主屏幕图标名称；实际主屏幕名称只在简体中文系统中观察到“有度”咩。
- 当前可用设备中没有紧凑型 iPhone 模拟器；自适应滚动布局已在 iPhone 18 Pro 与较小视口的 iPad mini 中检查，紧凑型 iPhone 的真实设备尺寸仍需补测咩。

## 截图

- [iPhone 18 Pro 中文不支持页](Phase9Evidence/iphone18-unsupported-zh-Hans.jpg)咩。
- [Phase 9.2 Release iPhone 模拟器不支持页](Phase9Evidence/iphone18-release-unsupported-zh-Hans.jpg)咩。
- [iPad mini 浅色不支持页](Phase9Evidence/ipad-mini-unsupported-light.jpg)咩。
- [iPad mini 深色不支持页](Phase9Evidence/ipad-mini-unsupported-dark.jpg)咩。

## 模拟器状态

- 测试后没有关闭或关机模拟器；iPhone 18 Pro、iPad mini 和 iPhone Duo 均保持开机咩。
