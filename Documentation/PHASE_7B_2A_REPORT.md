# Phase 7B.2A — Git 与 App Store Connect 准备

## Git 与项目配置

- 本次仅暂存签名迁移相关的 Xcode 项目设置与本报告；工作区中其他 StoreKit、Scheme、本地化及文档改动均保留在原状态咩。
- DuoAngle App target 的 Bundle Identifier 为 `com.hutianchi123.DuoAngle`，Debug 构建目标 Team ID 为 `9QSV394WZ5`，Automatic Signing 已开启咩。
- Xcode MCP 读取到 App target 的 `PRODUCT_BUNDLE_IDENTIFIER`、`DEVELOPMENT_TEAM`、`CODE_SIGN_STYLE` 分别为 `com.hutianchi123.DuoAngle`、`9QSV394WZ5`、`Automatic`咩。
- Release build settings 定向核对结果相同；未修改 StoreKit Product ID，也未批量改写测试 target、日志 subsystem 或历史文档中的旧标识符咩。
- 本次提交包含的差异仅为 App target Debug/Release Bundle ID 与各相关 target Team ID 调整；提交哈希及推送结果见本阶段交付信息咩。
- 提交作者邮箱使用已验证的 GitHub noreply 地址，未将私人邮箱写入提交元数据咩。
- 推送前将再次核对 outgoing diff、敏感信息扫描结果及 `origin/main`，不执行强推咩。

## Apple Developer 与签名

- Team ID `9QSV394WZ5` 下的显式 App ID `com.hutianchi123.DuoAngle` 已通过 Apple Developer 官方门户注册，门户列表显示它属于目标团队咩。
- Xcode MCP 通用 iOS Debug 构建成功，耗时约 0.37 秒咩。
- 构建产物签名标识为 `com.hutianchi123.DuoAngle`，TeamIdentifier 为 `9QSV394WZ5`，签名证书为 Apple Development；为避免在公开报告中暴露证书主体姓名，省略证书 CN 咩。
- 本次构建仍使用 `iOS Team Provisioning Profile: *` wildcard 开发 profile；因此仅能确认开发签名，不代表 App Store 分发签名已就绪咩。
- 未创建 Apple Distribution 证书、未上传构建、未提交审核咩。

## App Store Connect 与 IAP

- 此团队先前没有 Duo Angle 应用记录；创建时 Apple 提示名称 `Duo Angle` 已被占用咩。
- 按用户提供的候选顺序，`DuoAngle – Angle Meter` 创建成功咩。
- 应用记录为 iOS、主要语言简体中文、Bundle ID `com.hutianchi123.DuoAngle`、SKU `DuoAngle-iOS`，Apple ID 为 `6823964054`咩。
- 创建时选择有限访问权限；未配置价格、销售地区或提交审核咩。
- App Store Connect 内购买项目页面目前没有产品条目，故 `com.TNTstudio.DuoAngle.support.coffee` 尚未在该记录下配置咩。
- 本地 StoreKit 2 源码与 `.storekit` 配置仍使用 `com.TNTstudio.DuoAngle.support.coffee`；没有创建 IAP 或执行购买咩。

## 协议与分发状态

- App Store Connect 的 Business 页面持续停留在加载指示器，无法读取当前协议详情；上一阶段曾观察到 Paid Applications Agreement 过期，但本阶段无法再次确认其当前状态咩。
- 需由账户持有人在 App Store Connect 的 Business → Agreements, Tax, and Banking 页面确认 Paid Applications Agreement 状态；若仍过期，应先完成 Apple 要求的账户操作，代理未接受协议、未录入税务或银行信息咩。
- 分发签名尚未验证；wildcard 开发 profile 不是分发就绪凭据，后续需在确认协议和产品元数据后完成受控的 App Store 分发签名配置咩。

## 后续 Phase 7B.2B

- 确认 Paid Applications Agreement 当前状态并由账户持有人处理任何待办事项咩。
- 在 App Store Connect 为该应用创建并配置产品 `com.TNTstudio.DuoAngle.support.coffee`，包括 IAP 类型、本地化展示信息与定价；本阶段未替用户设置价格咩。
- 完成 Apple Distribution / App Store provisioning profile 配置与一次分发签名验证；本阶段未创建分发证书咩。
- 补齐商店元数据、隐私与审核材料，并由用户决定何时上传 TestFlight 或提交审核咩。
