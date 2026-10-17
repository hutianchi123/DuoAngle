# Duo Angle

Duo Angle 是一款面向兼容 iPhone Duo 设备的极简铰链角度测量应用。应用读取系统提供的铰链测量值，并通过自适应 SwiftUI 界面显示当前角度。

## 功能

- 实时显示铰链角度，并适配 Duo 的显示布局。
- 管理多个本地目标角度，支持启用、编辑和删除。
- 到达目标角度时提供触觉反馈。
- 通过 StoreKit 消耗型项目自愿支持开发者；应用全部功能仍可免费使用。
- 自动适配系统浅色和深色外观。
- 支持简体中文、繁体中文、英语、日语和韩语。
- 目标角度保存在设备本地，不会通过开发者自有服务器上传测量值，也没有分析 SDK。

## 技术与要求

- SwiftUI 和 StoreKit 2。
- Xcode 工程：`DuoAngle/DuoAngle.xcodeproj`。
- 最低部署版本：iOS 27.1；铰链测量使用兼容硬件提供的系统 API。
- iPhone Duo / iOS 27.1 模拟器可用于构建和界面检查；铰链测量和触觉反馈需在受支持的实体设备上验证。

## 构建

在 Xcode 中打开 `DuoAngle/DuoAngle.xcodeproj`，选择 `DuoAngle` scheme，并为支持的 iOS 模拟器或设备构建。实体设备构建需要可用的 Apple Developer team 和现有 Bundle Identifier 对应的签名配置。

## 隐私

请参阅[中文隐私政策](PRIVACY_POLICY.md)和[英文隐私政策](PRIVACY_POLICY_EN.md)。目标角度保存在本地；App Store 购买信息由 Apple StoreKit 处理。App Store 隐私问卷和公开联系邮箱仍需在发布前核实。

## 限制与状态

本仓库仍处于发布准备阶段。模拟器构建和界面检查不能验证真实铰链传感器或触觉反馈；本文不声称已完成实体 Duo 验证或 App Store 提交。App Store Connect 商品本地化和签名可用性仍取决于账户与团队配置。

## 许可证

本仓库未授予开源许可证；除非所有者另行添加许可证，源码权利仍予保留。
