#Requires AutoHotkey v2.0
#SingleInstance Force
InstallMouseHook
#MaxThreadsPerHotkey 3
Persistent

SetWorkingDir A_ScriptDir
CoordMode "Mouse", "Screen"
DetectHiddenWindows true
SetKeyDelay 10
A_BatchLines := -1
SetTitleMatchMode 2

; 获取完整命令行
full_command_line := DllCall("GetCommandLine", "Str")
if !(A_IsAdmin || RegExMatch(full_command_line, " /restart(?!\S)")) {
    try {
        if A_IsCompiled
            Run '*RunAs "' A_ScriptFullPath '" /restart'
        else
            Run '*RunAs "' A_AhkPath '" /restart "' A_ScriptFullPath '"'
    }
    ExitApp
}

; 基础变量定义
winTitle := "PopClipX"
dpiRatio := A_ScreenDPI/96
controlHight := 25
winHeightPx := controlHight * dpiRatio
bGColor := "000000"
fontColor := "ffffff"
ver := "2.0.0"
fontSize := 12
fontFamily := "微软雅黑"
userLanguage := "zh-CN"
VirtualWidth := SysGet(78)
VirtualHeight := SysGet(79)

; 读取配置文件中白名单列表
whiteListApps := IniRead(A_ScriptDir "\config.ini", "WhiteList", "apps", "")
global whiteList := Map()
if (whiteListApps != "") {
    for exe in StrSplit(whiteListApps, ",") {
        exe := Trim(exe)
        if (exe != "")
            whiteList[StrLower(exe)] := true
    }
}

; 全局变量声明
global savedClipboard := ""
global isPopClipXActive := false
global winClipToggle := 0
global selectText := ""
global linkText := ""
global linkButton := "🔗"
global mainGui := ""  ; 主界面对象
global transGui := ""  ; 翻译结果窗口对象

; 创建托盘菜单
TrayMenu := A_TrayMenu
TrayMenu.Delete()  ; 清除默认菜单项
TrayMenu.Add("更新 | Ver " ver, UpdateScript)
TrayMenu.Add("反馈 | Issues", Issues)
TrayMenu.Add()  ; 分隔符
TrayMenu.Add("重载 | Reload", ReloadScript)
TrayMenu.Add("退出 | Exit", ExitScript)

; 定义热键条件：若当前激活窗口不在白名单中
#HotIf !IsActiveWhiteList()
~LButton:: {
    global isPopClipXActive, mainGui, winTitle
    if isPopClipXActive {
        MouseGetPos(,,&mouseWin)
        if mouseWin {
            activeTitle := WinGetTitle("ahk_id " mouseWin)
            if (activeTitle != winTitle) {
                isPopClipXActive := false
                if mainGui {
                    mainGui.Destroy()
                }
            }
        }
    }
}

~RButton:: {
    global isPopClipXActive, mainGui
    if isPopClipXActive {
        isPopClipXActive := false
        if mainGui {
            mainGui.Destroy()
        }
    }
}

#HotIf IsActiveWhiteList()
$LButton:: {
    global isPopClipXActive, mainGui, winTitle
    if isPopClipXActive {
        MouseGetPos(,,&mouseWin)
        if mouseWin {
            activeTitle := WinGetTitle("ahk_id " mouseWin)
            if (activeTitle != winTitle) {
                isPopClipXActive := false
                if mainGui {
                    mainGui.Destroy()
                }
                HandleMouseClick()
            } else {
                Click
            }
        }
    } else {
        HandleMouseClick()
    }
}

$RButton:: {
    global isPopClipXActive, mainGui
    if isPopClipXActive {
        isPopClipXActive := false
        if mainGui {
            mainGui.Destroy()
        }
        Click "Right"
    } else {
        Click "Right"
    }
}

; 退出热键 Ctrl+Win+P
^#p::ExitApp()

;—————— 函数部分 ———————

IsActiveWhiteList() {
    global whiteList
    procName := WinGetProcessName("A")
    procNameLower := StrLower(procName)
    result := whiteList.Count > 0 ? whiteList.Has(procNameLower) : true  ; 如果白名单为空，则允许所有进程
    ;ToolTip "当前进程: " procName "`n白名单状态: " result
    ;SetTimer () => ToolTip(), -1000
    return result
}

ReloadScript(*) {
    Reload
}

UpdateScript(*) {
    Run "https://github.com/xinbs/PopClipX/releases"
}

Issues(*) {
    Run "https://github.com/xinbs/PopClipX/issues"
}

ExitScript(*) {
    ExitApp
}

HandleMouseClick() {
    global winTitle, winClipToggle, isPopClipXActive, perPosX, perPosY, preTime, win
    MouseGetPos(&perPosX, &perPosY)
    preTime := A_TickCount
    if (A_Cursor = "IBeam")
        winClipToggle := 1
    Click "Down"
    KeyWait "LButton"
    Click "Up"
    if (A_Cursor = "IBeam")
        winClipToggle := 1
    if !WinActive(winTitle) {
        win := WinExist("A")
        Sleep 100
        ShowMainGui(perPosX, perPosY, preTime)
    }
}

ShowMainGui(perPosX, perPosY, preTime) {
    global winHeightPx, winClipToggle, guiShowX, guiShowY
    curTime := A_TickCount
    lButtonDownDelay := curTime - preTime
    MouseGetPos(&curPosX, &curPosY)
    guiShowX := curPosX
    guiShowY := curPosY - winHeightPx * 2
    moveX := Abs(curPosX - perPosX)
    moveY := Abs(curPosY - perPosY)
    timeSinceHotkey := A_TimeSincePriorHotkey = "" ? 999999 : A_TimeSincePriorHotkey
    if ((timeSinceHotkey < 410) and (A_Cursor = "IBeam")) {
        Sleep 50
        if GetSelectText()
            ShowWinclip()
    } else if ((lButtonDownDelay > 250 and winClipToggle = 1) or (lButtonDownDelay > 350)) {
        if (moveX > 10 or moveY > 10) {
            Sleep 50
            if GetSelectText()
                ShowWinclip()
        }
    }
    winClipToggle := 0
}

GetSelectText() {
    global savedClipboard, selectText, linkText, linkButton
    savedClipboard := A_Clipboard
    A_Clipboard := ""
    Sleep 100
    
    ; 添加调试信息
    ToolTip "正在复制选中文本..."
    SetTimer () => ToolTip(), -1000
    
    Send "^c"
    if !ClipWait(0.5) {
        A_Clipboard := savedClipboard
        return false
    }
    if (A_Clipboard = "") {
        A_Clipboard := savedClipboard
        return false
    }
    selectText := A_Clipboard
    
    ; 添加调试信息
    ToolTip "已复制文本: " SubStr(selectText, 1, 50) "..."
    SetTimer () => ToolTip(), -1000
    
    linkText := ""
    linkButton := "🔗"
    
    ; URL匹配规则
    urlRegEx := "(?i)\b(https?://|www\d{0,3}[.][a-z0-9-]+[.][a-z]{2,4})[^\s<>]*[^\s.,<>]"
    if RegExMatch(selectText, urlRegEx, &match) {
        linkText := match[0]
        if !InStr(linkText, "http")
            linkText := "http://" linkText
    }
    
    ; IP地址匹配
    if (linkText = "") {
        ipRegEx := "(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])\.(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])\.(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])\.(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])"
        if RegExMatch(selectText, ipRegEx, &match)
            linkText := match[0]
    }
    
    ; B站视频链接匹配
    if (linkText = "") {
        if RegExMatch(selectText, "av\d+", &match) {
            linkText := "https://www.bilibili.com/video/" match[0]
            linkButton := "BiliBili"
        }
    }
    
    SetTimer RestoreClipboard, -100
    return true
}

RestoreClipboard() {
    global savedClipboard
    A_Clipboard := savedClipboard
    savedClipboard := ""
}

ShowWinclip() {
    global mainGui, fontSize, fontColor, fontFamily, controlHight
    global winClipToggle, selectText, linkText, linkButton, guiShowX, guiShowY, winTitle
    global VirtualWidth, dpiRatio, winHeightPx, isPopClipXActive
    
    if mainGui
        mainGui.Destroy()
    
    ; 创建窗口
    mainGui := Gui("-Caption +AlwaysOnTop +ToolWindow")
    mainGui.SetFont("s" fontSize " c" fontColor, fontFamily)
    
    ; 创建一个水平布局的工具栏
    mainGui.MarginX := 2
    mainGui.MarginY := 1
    
    ; 设置按钮样式
    buttonOpt := "h" controlHight " x+1"
    firstButtonOpt := "h" controlHight
    
    ; 添加按钮
    if RegExMatch(selectText, "^\s*$") {
        if (winClipToggle = 1) {
            mainGui.Add("Button", firstButtonOpt, " 全选 ").OnEvent("Click", SelectAll)
            mainGui.Add("Button", buttonOpt, " 粘贴 ").OnEvent("Click", Paste)
        }
    } else {
        mainGui.Add("Button", firstButtonOpt, " 🔍").OnEvent("Click", GoogleSearch)
        if (linkText != "")
            mainGui.Add("Button", buttonOpt, " " linkButton).OnEvent("Click", Link)
        mainGui.Add("Button", buttonOpt, " 全选 ").OnEvent("Click", SelectAll)
        if (winClipToggle = 1) {
            mainGui.Add("Button", buttonOpt, " 剪切 ").OnEvent("Click", Cut)
            mainGui.Add("Button", buttonOpt, " 复制 ").OnEvent("Click", Copy)
            mainGui.Add("Button", buttonOpt, " 粘贴 ").OnEvent("Click", Paste)
        } else {
            mainGui.Add("Button", buttonOpt, " 复制 ").OnEvent("Click", Copy)
        }
        mainGui.Add("Button", buttonOpt, " 翻译 ").OnEvent("Click", DeepSeekTranslate)
        mainGui.Add("Button", buttonOpt, " ❓").OnEvent("Click", DeepSeekAsk)
        mainGui.Add("Button", buttonOpt, " ✍").OnEvent("Click", DeepSeekRewrite)
        mainGui.Add("Button", buttonOpt, " 📝").OnEvent("Click", DeepSeekGrammar)
    }
    
    ; 显示窗口
    mainGui.Title := winTitle
    mainGui.Show(Format("AutoSize x{1} y{2}", guiShowX, guiShowY))
    
    ; 获取窗口位置和大小
    hwnd := mainGui.Hwnd
    WinGetPos(&x, &y, &w, &h, "ahk_id " hwnd)
    
    ; 计算新位置
    winMoveX := x - w/2
    if (winMoveX > VirtualWidth - w + 15 * dpiRatio)
        winMoveX := VirtualWidth - w + 15 * dpiRatio
    winMoveY := Max(y, 0)
    
    ; 移动窗口 - 使用实际高度而不是固定高度
    WinMove winMoveX, winMoveY, w, h, "ahk_id " hwnd
    
    isPopClipXActive := true
}

WatchMouse() {
    global mainGui, isPopClipXActive, winTitle
    static watchCount := 0
    
    watchCount++
    ToolTip "WatchMouse运行中... 第" watchCount "次"
    SetTimer () => ToolTip(), -200
    
    if !mainGui {
        SetTimer () => WatchMouse(), 0
        return
    }
    
    ; 检查鼠标位置
    MouseGetPos(&mouseX, &mouseY, &mouseWin)
    if !mouseWin {
        return
    }
    
    ; 获取当前激活窗口的标题
    activeTitle := WinGetTitle("ahk_id " mouseWin)
    
    ; 如果鼠标不在主窗口上且当前窗口不是工具栏
    if (mouseWin != mainGui.Hwnd && activeTitle != winTitle) {
        SetTimer () => WatchMouse(), 0
        isPopClipXActive := false
        mainGui.Destroy()
        ToolTip "工具栏已关闭"
        SetTimer () => ToolTip(), -1000
    }
}

SelectAll(*) {
    global mainGui, win
    if mainGui
        mainGui.Destroy()
    WinActivate "ahk_id " win
    WinWaitActive "ahk_id " win, , 1
    Send "^a"
    Sleep 100
    GetSelectText()
    ShowWinclip()
}

Copy(*) {
    global mainGui, selectText, win
    if mainGui
        mainGui.Destroy()
    if (selectText != "") {
        A_Clipboard := selectText
        ClipWait 1
        WinActivate "ahk_id " win
        WinWaitActive "ahk_id " win, , 1
    }
}

Cut(*) {
    Copy()
    Send "{Delete}"
}

Paste(*) {
    global mainGui, win
    if mainGui
        mainGui.Destroy()
    WinActivate "ahk_id " win
    WinWaitActive "ahk_id " win, , 1
    Send "^v"
    Sleep 100
}

Link(*) {
    global mainGui, linkText
    if mainGui
        mainGui.Destroy()
    try Run linkText
}

DeepSeekAsk(*) {
    global mainGui, selectText
    if mainGui
        mainGui.Destroy()
    result := DeepSeekAskText(selectText)
    ShowTranslationResult(result)
}

DeepSeekAskText(text) {
    IniFile := A_ScriptDir "\config.ini"
    apiKey := IniRead(IniFile, "DeepSeek", "apiKey", "")
    if (apiKey = "")
        return "请先配置 API Key"
    apiKey := RegExReplace(apiKey, "[\s\r\n]+")
    if (apiKey = "")
        return "API Key 格式不正确"
    try {
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        url := "https://api.deepseek.com/v1/chat/completions"
        whr.Open("POST", url, true)
        whr.SetRequestHeader("Content-Type", "application/json; charset=utf-8")
        whr.SetRequestHeader("Authorization", "Bearer " apiKey)
        whr.SetRequestHeader("Accept", "application/json; charset=utf-8")
        whr.Option[9] := 2048
        whr.Option[6] := false
        systemPrompt := "你现在是一个百科全书，请用简洁的中文解释这个问题"
        text := StrReplace(text, '\', '\\')
        text := StrReplace(text, '`"', '\"')
        text := StrReplace(text, '`n', '\n')
        text := StrReplace(text, '`r', '\r')
        text := StrReplace(text, '`t', '\t')
        postData := Format('{"model":"deepseek-chat","messages":[{"role":"system","content":"{1}"},{"role":"user","content":"{2}"}],"temperature":0.3}', systemPrompt, text)
        whr.Send(postData)
        whr.WaitForResponse()
        responseBody := whr.ResponseBody
        ADO := ComObject("ADODB.Stream")
        ADO.Type := 1
        ADO.Mode := 3
        ADO.Open()
        ADO.Write(responseBody)
        ADO.Position := 0
        ADO.Type := 2
        ADO.Charset := "UTF-8"
        response := ADO.ReadText()
        ADO.Close()
        status := whr.Status
        if (status != 200)
            return "问答请求失败：HTTP状态码 " status "`n响应内容：" response
        contentPattern := '"content":\s*"([^"]+)"'
        if RegExMatch(response, contentPattern, &match)
            return match[1]
        else
            return "问答失败，未能解析API响应：" response
    } catch Error as e {
        return "问答请求失败：" e.Message
    }
}

DeepSeekRewrite(*) {
    global mainGui, selectText
    if mainGui
        mainGui.Destroy()
    result := DeepSeekRewriteText(selectText)
    ShowTranslationResult(result)
}

DeepSeekRewriteText(text) {
    IniFile := A_ScriptDir "\config.ini"
    apiKey := IniRead(IniFile, "DeepSeek", "apiKey", "")
    if (apiKey = "")
        return "请先配置 API Key"
    apiKey := RegExReplace(apiKey, "[\s\r\n]+")
    if (apiKey = "")
        return "API Key 格式不正确"
    try {
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        url := "https://api.deepseek.com/v1/chat/completions"
        whr.Open("POST", url, true)
        whr.SetRequestHeader("Content-Type", "application/json; charset=utf-8")
        whr.SetRequestHeader("Authorization", "Bearer " apiKey)
        whr.SetRequestHeader("Accept", "application/json; charset=utf-8")
        whr.Option[9] := 2048
        whr.Option[6] := false
        systemPrompt := "你现在是一个专业的文本重写助手。请将以下文本重写为更简洁或更丰富的表达方式。"
        text := StrReplace(text, '\', '\\')
        text := StrReplace(text, '`"', '\"')
        text := StrReplace(text, '`n', '\n')
        text := StrReplace(text, '`r', '\r')
        text := StrReplace(text, '`t', '\t')
        postData := Format('{"model":"deepseek-chat","messages":[{"role":"system","content":"{1}"},{"role":"user","content":"{2}"}],"temperature":0.3}', systemPrompt, text)
        whr.Send(postData)
        whr.WaitForResponse()
        responseBody := whr.ResponseBody
        ADO := ComObject("ADODB.Stream")
        ADO.Type := 1
        ADO.Mode := 3
        ADO.Open()
        ADO.Write(responseBody)
        ADO.Position := 0
        ADO.Type := 2
        ADO.Charset := "UTF-8"
        response := ADO.ReadText()
        ADO.Close()
        status := whr.Status
        if (status != 200)
            return "重写请求失败：HTTP状态码 " status "`n响应内容：" response
        contentPattern := '"content":\s*"([^"]+)"'
        if RegExMatch(response, contentPattern, &match)
            return match[1]
        else
            return "重写失败，未能解析API响应：" response
    } catch Error as e {
        return "重写请求失败：" e.Message
    }
}

DeepSeekGrammar(*) {
    global mainGui, selectText
    if mainGui
        mainGui.Destroy()
    result := DeepSeekGrammarText(selectText)
    ShowTranslationResult(result)
}

DeepSeekGrammarText(text) {
    IniFile := A_ScriptDir "\config.ini"
    apiKey := IniRead(IniFile, "DeepSeek", "apiKey", "")
    if (apiKey = "")
        return "请先配置 API Key"
    apiKey := RegExReplace(apiKey, "[\s\r\n]+")
    if (apiKey = "")
        return "API Key 格式不正确"
    try {
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        url := "https://api.deepseek.com/v1/chat/completions"
        whr.Open("POST", url, true)
        whr.SetRequestHeader("Content-Type", "application/json; charset=utf-8")
        whr.SetRequestHeader("Authorization", "Bearer " apiKey)
        whr.SetRequestHeader("Accept", "application/json; charset=utf-8")
        whr.Option[9] := 2048
        whr.Option[6] := false
        systemPrompt := "你现在是一位专业的英语语法专家。请检查以下英文文本是否有语法错误或者是单词拼写错误。如果有错误，请直接返回修正后的文本；如果没有错误，请直接返回原文。不需要解释。待检查内容是："
        text := StrReplace(text, '\', '\\')
        text := StrReplace(text, '`"', '\"')
        text := StrReplace(text, '`n', '\n')
        text := StrReplace(text, '`r', '\r')
        text := StrReplace(text, '`t', '\t')
        postData := Format('{"model":"deepseek-chat","messages":[{"role":"system","content":"{1}"},{"role":"user","content":"{2}"}],"temperature":0.1}', systemPrompt, text)
        whr.Send(postData)
        whr.WaitForResponse()
        responseBody := whr.ResponseBody
        ADO := ComObject("ADODB.Stream")
        ADO.Type := 1
        ADO.Mode := 3
        ADO.Open()
        ADO.Write(responseBody)
        ADO.Position := 0
        ADO.Type := 2
        ADO.Charset := "UTF-8"
        response := ADO.ReadText()
        ADO.Close()
        status := whr.Status
        if (status != 200)
            return "语法检查请求失败：HTTP状态码 " status "`n响应内容：" response
        contentPattern := '"content":\s*"([^"]+)"'
        if RegExMatch(response, contentPattern, &match)
            return match[1]
        else
            return "语法检查失败，未能解析API响应：" response
    } catch Error as e {
        return "语法检查请求失败：" e.Message
    }
}

GoogleSearch(*) {
    global mainGui, selectText
    if mainGui
        mainGui.Destroy()
    urlEncodedText := UriEncode(selectText)
    Run "https://www.google.com/search?ie=utf-8&oe=utf-8&q=" urlEncodedText
}

DeepSeekTranslate(*) {
    global mainGui, selectText
    if mainGui
        mainGui.Destroy()
    result := DeepSeekTranslateText(selectText)
    ShowTranslationResult(result)
}

DeepSeekTranslateText(text) {
    IniFile := A_ScriptDir "\config.ini"
    apiKey := IniRead(IniFile, "DeepSeek", "apiKey", "")
    if (apiKey = "")
        return "请先配置 API Key"
    apiKey := RegExReplace(apiKey, "[\s\r\n]+")
    if (apiKey = "")
        return "API Key 格式不正确"
    try {
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        url := "https://api.deepseek.com/v1/chat/completions"
        whr.Open("POST", url, true)
        whr.SetRequestHeader("Content-Type", "application/json; charset=utf-8")
        whr.SetRequestHeader("Authorization", "Bearer " apiKey)
        whr.SetRequestHeader("Accept", "application/json; charset=utf-8")
        whr.Option[9] := 2048
        whr.Option[6] := false
        systemPrompt := "你是一个专业的翻译助手。如果输入的是中文就翻译成英文，如果输入的是英文就翻译成中文。只返回翻译结果，不要包含任何解释或其他内容。"
        text := StrReplace(text, '\', '\\')
        text := StrReplace(text, '`"', '\"')
        text := StrReplace(text, '`n', '\n')
        text := StrReplace(text, '`r', '\r')
        text := StrReplace(text, '`t', '\t')
        postData := Format('{"model":"deepseek-chat","messages":[{"role":"system","content":"{1}"},{"role":"user","content":"{2}"}],"temperature":0.3}', systemPrompt, text)
        whr.Send(postData)
        whr.WaitForResponse()
        responseBody := whr.ResponseBody
        ADO := ComObject("ADODB.Stream")
        ADO.Type := 1
        ADO.Mode := 3
        ADO.Open()
        ADO.Write(responseBody)
        ADO.Position := 0
        ADO.Type := 2
        ADO.Charset := "UTF-8"
        response := ADO.ReadText()
        ADO.Close()
        status := whr.Status
        if (status != 200)
            return "翻译请求失败：HTTP状态码 " status "`n响应内容：" response
        contentPattern := '"content":\s*"([^"]+)"'
        if RegExMatch(response, contentPattern, &match)
            return match[1]
        else
            return "翻译失败，未能解析API响应：" response
    } catch Error as e {
        return "翻译请求失败：" e.Message
    }
}

ShowTranslationResult(text) {
    global transGui  ; 确保 transGui 是全局变量
    
    text := StrReplace(text, "\n", "`n")
    MouseGetPos(&mouseX, &mouseY)
    
    ; 获取工作区域（排除任务栏）
    MonitorWorkArea := {}
    MonitorWorkArea.Left := SysGet(76)    ; SM_XVIRTUALSCREEN
    MonitorWorkArea.Top := SysGet(77)     ; SM_YVIRTUALSCREEN
    MonitorWorkArea.Right := SysGet(78)   ; SM_CXVIRTUALSCREEN
    MonitorWorkArea.Bottom := SysGet(79)  ; SM_CYVIRTUALSCREEN
    
    ; 如果已存在翻译窗口，先销毁
    if transGui {
        transGui.Destroy()
    }
    
    windowWidth := 450
    windowHeight := 350
    editWidth := windowWidth - 20
    transGui := Gui("+AlwaysOnTop +Owner")  ; 移除 +E0x08000000 标志
    transGui.SetFont("s10", "Microsoft YaHei")
    transGui.Add("Edit", "x10 y10 w" editWidth " h" windowHeight " ReadOnly +Multi +VScroll +Wrap", text)
    buttonY := windowHeight + 10
    buttonWidth := 80
    
    copyBtn := transGui.Add("Button", "x10 y" buttonY " w" buttonWidth, "复制")
    copyBtn.OnEvent("Click", CopyTransResult.Bind(text))
    
    closeBtn := transGui.Add("Button", "x" (10 + buttonWidth + 10) " y" buttonY " w" buttonWidth, "关闭")
    closeBtn.OnEvent("Click", (*) => transGui.Destroy())
    
    winX := mouseX
    winY := mouseY - windowHeight - 50
    if (winX + windowWidth > MonitorWorkArea.Right)
        winX := MonitorWorkArea.Right - windowWidth
    if (winX < MonitorWorkArea.Left)
        winX := MonitorWorkArea.Left
    if (winY + windowHeight + 50 > MonitorWorkArea.Bottom)
        winY := MonitorWorkArea.Bottom - windowHeight - 50
    if (winY < MonitorWorkArea.Top)
        winY := mouseY + 20
    totalHeight := windowHeight + 45
    
    transGui.OnEvent("Close", (*) => transGui.Destroy())
    transGui.OnEvent("Escape", (*) => transGui.Destroy())
    
    transGui.Title := "结果"
    options := Format("x{1} y{2} w{3} h{4}", winX, winY, windowWidth, totalHeight)
    transGui.Show(options)
}

UriEncode(Uri, Mode := 0, RE := "[0-9A-Za-z]") {
    buf := Buffer(StrPut(Uri, "UTF-8"), 0)
    StrPut(Uri, buf, "UTF-8")
    Res := ""
    loop buf.Size - 1 {
        Code := NumGet(buf, A_Index - 1, "UChar")
        CharStr := Chr(Code)
        if RegExMatch(CharStr, RE)
            Res .= CharStr
        else
            Res .= "%" Format("{:02X}", Code)
    }
    Res := StrReplace(Res, "&", "%26")
    Res := StrReplace(Res, "`n", "%0A")
    if (Mode = 1)
        Res := StrReplace(Res, "%2F", "%5C%2F")
    return Res
}

GuiClose(*) {
    global mainGui, isPopClipXActive
    if mainGui {
        isPopClipXActive := false
        mainGui.Destroy()
    }
}

CopyTransResult(text, *) {
    global transGui
    A_Clipboard := text
    if transGui {
        transGui.Destroy()
    }
}

CloseTransResult(*) {
    global transGui
    if transGui {
        transGui.Destroy()
    }
}