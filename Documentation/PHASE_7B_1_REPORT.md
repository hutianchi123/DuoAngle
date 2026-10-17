# Phase 7B.1 实施报告

**日期：2026-10-17**

## 完成内容

- 已为界面、验证与恢复提示、StoreKit 状态、无障碍文案建立 String Catalog，源语言为 `zh-Hans`，支持简体中文、繁体中文、英语、日语和韩语，共 53 个文案 key；计数文案使用原生复数变体。
- Release 构建产物中确认存在 `zh-Hans.lproj`、`zh-Hant.lproj`、`en.lproj`、`ja.lproj`、`ko.lproj` 五种资源。
- 移除 MainView 面向用户的诊断开关和关联展示状态；运行时主界面语义快照显示测量值和两个操作，没有诊断按钮。
- 保留源图的深色外观，并从同一图形做逐像素颜色反转浅色版本；两个导出均为不透明 1024×1024 PNG。Xcode Asset Catalog 预览显示 Any Appearance 使用浅色图、Dark 使用深色图、Tinted 留空；未另行绘制圆角蒙版。
- 隐私审查确认：目标角度仅保存在本机 `UserDefaults`；铰链测量在运行时处理；StoreKit 2 处理可选消耗型支持商品；未发现自有网络 API、分析/广告 SDK、设备标识访问、相机/麦克风权限或数据共享功能。OSLog 仅记录铰链状态变化和 StoreKit 错误类型，不记录角度值。
- 新增中英文隐私政策、App Store 隐私核对清单和有效的 `PrivacyInfo.xcprivacy`。清单声明 UserDefaults 的 `CA92.1` 使用原因，无收集数据类别、无跟踪；Release.app 中的隐私清单通过 plist 校验。
- 新增英文与简体中文 README，未添加开源许可证；隐私政策联系邮箱、App Store Connect 隐私问卷和商品元数据仍需发布前人工确认。

## Apple Developer 团队迁移

Xcode 账户中可见新账户及管理员团队 “Ya Jun Hu Developer Team”，并显示 6 台已配置设备；账户证书管理面板显示开发证书记录。但本机 `security find-identity` 报告 0 个有效签名身份，下载手动描述文件后本地仍没有 Provisioning Profile，Xcode 账户界面也未显示 Team ID。当前目标仍使用旧团队 `79W6NG56BQ`。

由于无法验证新团队中现有 Bundle ID `com.TNTstudio.DuoAngle` 的 App ID、有效私钥/签名身份和匹配的 Provisioning Profile，未更改团队签名设置，也未启用可能自动创建 App ID、证书或描述文件的选项。Bundle Identifier 与 StoreKit Product ID `com.TNTstudio.DuoAngle.support.coffee` 均保持不变；团队迁移为明确阻塞项。

## GitHub 与安全检查

- GitHub API 确认 `https://github.com/hutianchi123/DuoAngle` 已存在、公开，当前连接账号具备推送权限。
- 对全部 243 个历史 Git blob、工作区已跟踪/未跟踪/忽略文件执行凭据模式与敏感文件名扫描；未发现 API token、私钥/证书内容或匹配凭据模式。额外的邮箱扫描在 Codex 内部 `refs/codex/turn-diffs` 快照引用中发现一份历史设计草稿曾含 Apple 账户邮箱；当前提交候选已删除该邮箱。
- `.DS_Store`、Xcode `xcuserdata`、用户已有的 `Documentation` 文档及临时状态均未纳入提交；仅把用户提供的 `icon.png` 作为本阶段明确使用的项目图稿纳入候选文件。
- 本阶段规则要求发现历史敏感信息后暂停公开推送，且不得改写历史；因此即使该内部快照引用不属于 `main` 的待推送提交图，本次仍只保留本地提交、不推送公开仓库，待用户决定历史快照的处理方式。

## 构建与定向检查

- Debug 模拟器构建：通过，无警告。
- Release 模拟器构建：通过，无警告；五语言资源与隐私清单均包含在应用包中。
- iPhone Duo / iOS 27.1 Simulator：应用成功启动；当前中文界面快照无诊断按钮。
- Xcode Asset Catalog 已显示浅色、深色变体预览；源与导出图像尺寸、alpha 边缘及目录引用已检查。
- 按要求未运行完整回归测试、测试套件或真实购买；本轮没有完成角度设置页/支持页的完整交互检查，也没有实体 Duo 验证。模拟器保持开机。

## 发布前事项

1. 在 Apple Developer 后台确认团队 Team ID、现有 App ID、有效签名私钥及匹配的 Provisioning Profile 后，再通过 Xcode 切换团队；不得更改应用或商品标识符。
2. 补齐公开联系邮箱，将隐私政策发布到稳定 URL，并在 App Store Connect 填写隐私披露及商品本地化。
3. 在真实兼容设备上验证铰链测量和触觉反馈；Phase 7B.2 与 App Store 提交不属于本阶段。
