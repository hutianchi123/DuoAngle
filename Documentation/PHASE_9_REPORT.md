# Phase 9 完成报告

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
- [iPad mini 浅色不支持页](Phase9Evidence/ipad-mini-unsupported-light.jpg)咩。
- [iPad mini 深色不支持页](Phase9Evidence/ipad-mini-unsupported-dark.jpg)咩。

## 模拟器状态

- 测试后没有关闭或关机模拟器；iPhone 18 Pro、iPad mini 和 iPhone Duo 均保持开机咩。
