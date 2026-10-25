# Phase 8 报告

- 应用界面：在现有支持开发页面的 StoreKit 区域下方增加 GitHub 和开发者邮箱两行系统 `Link`；原购买流程、商品标识、Bundle Identifier 和版本号均未修改。应用内没有微信收款入口。
- 本地化：新增 GitHub、项目源码说明、联系开发者文案；简体中文、繁体中文、英语、日语、韩语均已写入现有 String Catalog。
- 链接核对：GitHub 仓库和 App Store 下载页均可公开访问。界面测试确认 GitHub 行打开 Safari，邮箱行可见且可点击；这台模拟器没有打开 Mail 或显示邮件提示，邮件处理器仍需在已配置邮箱的设备上确认。Duo 模拟器的远程截图全黑，无法据此做视觉验收。
- README：`README.md` 为简体中文首页，`README.en.md` 为英文版；双向语言链接、截图、隐私、联系信息及源码使用说明已更新。旧的 `README.zh-CN.md` 指向中文首页。
- 微信二维码：原文件 `Documentation/wechat-coffee.JPG` 保持不变，仅在 GitHub README 中展示；图像可正常打开。
- 隐私政策：中英文文件中的联系邮箱占位符已改为 `hutianchi3622@gmail.com`，数据处理声明未改动。
- 构建与测试：Xcode MCP 的 iPhone Duo / iOS 27.1 Debug 构建成功；`testBottomActionsPresentAndDismissSheets` 单项界面测试通过，涵盖支持页与模拟 StoreKit 按钮；外链单项测试确认 GitHub 跳转及邮箱行可访问。模拟器在测试后保持开机。
- Git：使用提交消息 `feat: add developer links and refresh project README` 单次提交并推送至 `origin/main`；只暂存 Phase 8 文件，保留此前未提交的本地改动。公开 GitHub 页面的最终渲染以推送后检查结果为准。
- 后续 App Store 更新：在可交互模拟器或实体设备确认两种外部链接、浅色与深色布局和动态字体；按需准备 1.0.1 的新构建，完成实体 Duo 验证后再考虑归档、TestFlight 和 App Review。本阶段未上传新版本。
