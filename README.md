# PopClipX

Windows 下的 PopClip，基于 AutoHotkey 实现。

## 功能

- 选中文本后快速搜索、复制、剪切、粘贴
- 自动识别链接，支持一键打开
- 支持 DeepSeek 翻译（中英互译）
- 支持白名单应用配置

## 使用方法

1. 下载并安装 [AutoHotkey](https://www.autohotkey.com/)
2. 下载本项目
3. 复制 `config.ini.example` 为 `config.ini`
4. 配置 DeepSeek API Key（可选，用于翻译功能）
5. 运行 `WinPopClip.ahk`

## 配置说明

配置文件为 `config.ini`，包含以下配置项：

### DeepSeek 翻译配置

```ini
[DeepSeek]
apiKey=YOUR_API_KEY  # 在 https://platform.deepseek.com/ 获取
```

### 应用程序配置

```ini
[WhiteList]
# 白名单：只有列表中的应用程序启用功能（逗号分隔）
apps=notepad.exe,chrome.exe
```

## 注意事项

1. 需要以管理员权限运行才能在管理员权限的程序中使用
2. 翻译功能需要配置 DeepSeek API Key
3. 只有在白名单中的应用程序才会启用增强功能

## 反馈

如有问题或建议，欢迎提交 [Issues](https://github.com/xinbs/PopClipX/issues)
