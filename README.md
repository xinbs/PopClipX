# PopClipX

PopClipX 是一个在 Windows 上实现的文本选择增强工具，提供类似 macOS 上 PopClip 的功能，使用 AutoHotkey 编写。

## 功能特点

* 选中文本后自动弹出操作菜单
* 支持搜索、复制、剪切、粘贴等基本操作
* 支持链接识别和快速打开
* 支持 B 站视频链接识别
* 集成 DeepSeek AI 翻译功能（需要 API Key）
* 支持白名单应用配置

## 使用方法

1. 从官网下载并安装 [AutoHotkey](https://www.autohotkey.com/)
2. 下载 PopClipX 源码并解压
3. 双击 PopClipX.ahk 运行脚本

## 配置说明

* 在 `White List.txt` 中添加需要启用的应用程序名称
* 复制 `config.ini.example` 为 `config.ini` 并填入您的 DeepSeek API Key
* 可以根据需要调整界面字体、颜色等参数

### DeepSeek API 配置
1. 访问 [DeepSeek Platform](https://platform.deepseek.com/) 获取 API Key
2. 将 `config.ini.example` 重命名为 `config.ini`
3. 在 `config.ini` 中填入您的 API Key

## 更新日志

### v1.0.0
* 集成 DeepSeek AI 翻译功能
* 优化翻译结果显示界面
* 改进窗口位置计算逻辑
* 修复中文编码问题
* 移除 Google 翻译和 DeepL 翻译功能
* 改进错误处理和提示

## 其他说明

* 更多功能会逐步完善
* 欢迎提交 Issue 反馈问题或建议

## 捐赠

如果这个脚本对您有帮助，您可以选择捐赠以支持开发。

### 通过 Paypal 捐赠

或者通过以下方式：

| 微信 | 支付宝 |
|-----|--------|
| [微信二维码] | [支付宝二维码] |
