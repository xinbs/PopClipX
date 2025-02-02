# PopClipX

PopClipX 是一个在 Windows 上实现的文本选择增强工具，提供类似 macOS 上 PopClip 的功能，使用 AutoHotkey 编写。

## 功能特点

* 选中文本后自动弹出操作菜单
* 支持搜索、复制、剪切、粘贴等基本操作
* 支持链接识别和快速打开
* 支持 B 站视频链接识别
* 集成 DeepSeek AI 翻译功能（需要 API Key）
* 支持白名单/黑名单模式配置
* 支持自定义应用程序列表

## 使用方法

1. 从官网下载并安装 [AutoHotkey](https://www.autohotkey.com/)
2. 下载 PopClipX 源码并解压
3. 复制 `config.ini.example` 为 `config.ini` 并进行配置
4. 双击 PopClipX.ahk 运行脚本

## 配置说明

配置文件 `config.ini` 包含以下部分：

### DeepSeek API 配置
```ini
[DeepSeek]
apiKey=YOUR_API_KEY  # 在此填入你的 DeepSeek API Key
```
获取 API Key：访问 [DeepSeek Platform](https://platform.deepseek.com/)

### 应用程序模式配置
```ini
[AppList]
mode=whitelist  # 可选：whitelist（白名单模式）或 blacklist（黑名单模式）
```

### 白名单配置
```ini
[WhiteList]
# 白名单模式下，只有列表中的应用程序启用功能
apps=chrome.exe,notepad.exe,word.exe
```

### 黑名单配置
```ini
[BlackList]
# 黑名单模式下，列表中的应用程序不启用功能，其他程序都启用
apps=cmd.exe,powershell.exe
```

## 工作模式说明

### 白名单模式 (默认)
- 设置 `mode=whitelist`
- 只有在白名单列表中的应用程序才会启用 PopClipX 功能
- 适合只想在特定应用中使用的场景

### 黑名单模式
- 设置 `mode=blacklist`
- 除了黑名单列表中的应用程序，其他所有程序都会启用 PopClipX 功能
- 适合想在大多数应用中使用，只排除少数应用的场景

## 更新日志

### v1.1.0
* 新增黑名单模式支持
* 优化配置文件结构
* 改进应用程序列表管理
* 修复已知问题

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
