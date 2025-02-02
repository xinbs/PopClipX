#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, force
#InstallMouseHook
AutoTrim, Off
CoordMode, Mouse, Screen
DetectHiddenWindows, On
ListLines Off
SendMode, Input ; Recommended for new scripts due to its superior speed and reliability.
SetBatchLines -1
SetWorkingDir %A_ScriptDir% ; Ensures a consistent starting directory.

full_command_line := DllCall("GetCommandLine", "str")

if not (A_IsAdmin or RegExMatch(full_command_line, " /restart(?!\S)"))
{
    try
    {
        if A_IsCompiled
            Run *RunAs "%A_ScriptFullPath%" /restart
        else
            Run *RunAs "%A_AhkPath%" /restart "%A_ScriptFullPath%"
    }
    ExitApp
}

; MsgBox A_IsAdmin: %A_IsAdmin%`nCommand line: %full_command_line%

winTitle:="PopClipX"
dpiRatio:=A_ScreenDPI/96
controlHight:=25
winHeightPx:=controlHight*dpiRatio
bGColor:="000000"
fontColor:="ffffff"
ver:="1.1.0"
fontSize:=12
fontFamily:="微软雅黑"
userLanguage:="zh-CN"
SysGet, VirtualWidth, 78
SysGet, VirtualHeight, 79

; 从配置文件读取应用列表模式和列表
IniRead, whiteListApps, %A_ScriptDir%\config.ini, WhiteList, apps

; 设置菜单
Menu, tray, NoStandard
Menu, tray, add, 更新 | Ver %ver%, UpdateScrit
Menu, tray, add, 反馈 | Issues, Issues
;Menu, tray, add, 暂停 | Pause, PauseScrit
Menu, tray, add
Menu, tray, add, 重载 | Reload, ReloadScrit
Menu, tray, add, 退出 | Exit, ExitScrit

; 创建白名单组
if (whiteListApps != "ERROR") {
    Loop, Parse, whiteListApps, `,, %A_Space%%A_Tab%
    {
        if (A_LoopField != "") {
            GroupAdd, whiteList, ahk_exe %A_LoopField%
        }
    }
}

; 白名单模式的热键定义
#IfWinNotActive ahk_group whiteList
~LButton::
    Gui,Destroy
Return
#IfWinNotActive

#IfWinActive ahk_group whiteList
$LButton::
    HandleMouseClick()
Return
#IfWinActive

; 菜单处理函数
ReloadScrit:
    Reload
Return

PauseScrit:
    Pause, Toggle, 1
Return

UpdateScrit:
    Run, https://github.com/xinbs/PopClipX/releases
Return

Issues:
    Run, https://github.com/xinbs/PopClipX/issues
Return

ExitScrit:
^#p::
ExitApp
Return

ShowMainGui(perPosX,perPosY,preTime)
{
    global
    ; 获得当前时间
    curTime:=A_TickCount
    ; 当前时间减去之前时间
    lButtonDownDelay:=curTime-preTime

    ; 获得鼠标当前坐标
    MouseGetPos, curPosX, curPosY

    guiShowX:=curPosX
    guiShowY:=curPosY-winHeightPx*2 ;*dpiRatio

    If (A_TimeSincePriorHotkey < 410) && (A_Cursor="IBeam")
    {

        GetSelectText()
        ShowWinclip()
    }
    Else if (lButtonDownDelay > 250 && winClipToggle=1) || (lButtonDownDelay > 350)
    {
        ; 当前坐标剪去先前坐标
        moveX:=abs(curPosX-perPosX)
        moveY:=abs(curPosY-perPosY)

        ; 如果X大于10，Y大于10, 在当前坐标弹出界面
        If (moveX>10) || (moveY>10)
        {
            GetSelectText()
            ShowWinclip()
        }
    }
    Else
    {
        Gui, Destroy
    }

    winClipToggle:=0
}

GetSelectText()
{
    global
    ; 保存选中的文本
    Clipboard := ""  ; 清空剪贴板
    Send, ^c  ; 发送复制命令
    ClipWait, 0.5  ; 等待剪贴板更新
    selectText := Clipboard  ; 保存选中的文本
    
    ; 处理协议地址
    linkText := ""
    linkButton := "🔗"
    
    ; 检查普通URL
    urlRegEx := "(?:(?:https?|ftp|file|ed2k|steam|thunder)://)(?:\S+(?::\S*)?@)?(?:(?!10(?:\.\d{1,3}){3})(?!127(?:\.\d{1,3}){3})(?!169\.254(?:\.\d{1,3}){2})(?!192\.168(?:\.\d{1,3}){2})(?!172\.(?:1[6-9]|2\d|3[0-1])(?:\.\d{1,3}){2})(?:[1-9]\d?|1\d\d|2[01]\d|22[0-3])(?:\.(?:1?\d{1,2}|2[0-4]\d|25[0-5])){2}(?:\.(?:[1-9]\d?|1\d\d|2[0-4]\d|25[0-4]))|(?:(?:[a-z\x{00a1}-\x{ffff}0-9]+-?)*[a-z\x{00a1}-\x{ffff}0-9]+)(?:\.(?:[a-z\x{00a1}-\x{ffff}0-9]+-?)*[a-z\x{00a1}-\x{ffff}0-9]+)*(?:\.(?:[a-z\x{00a1}-\x{ffff}]{2,})))(?::\d{2,5})?(?:/[^\s]*)?"
    RegExMatch(selectText, urlRegEx, linkText)
    
    ; 检查IP地址
    if (linkText = "") {
        urlRegEx := "(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])\.(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])\.(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])\.(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])"
        RegExMatch(selectText, urlRegEx, ipText)
        if (ipText != "")
            linkText := ipText
    }
    
    ; 检查其他URL格式
    if (linkText = "") {
        urlRegEx := "(?i)\b((?:https?://|www\d{0,3}[.]|[a-z0-9.\-]+[.][a-z]{2,4}/)(?:[^\s()<>]+|\(([^\s()<>]+|(\([^\s()<>]+\)))*\))+(?:\(([^\s()<>]+|(\([^\s()<>]+\)))*\)|[^\s`!()\[\]{};:'.,<>?«»""'']))"
        RegExMatch(selectText, urlRegEx, linkText)
        if (linkText != "" && !InStr(linkText, "http"))
            linkText := "http://" . linkText
    }
    
    ; 检查B站视频链接
    if (linkText = "") {
        RegExMatch(selectText, "av\d+", bilibili)
        if (bilibili != "") {
            linkText := "https://www.bilibili.com/video/" . bilibili
            linkButton := "BiliBili"
        }
    }

    ShowWinclip()
}

ShowWinclip()
{
    global
    local x,y,w,h,winMoveX,winMoveY
    ;ToolTip, %selectText%
    Gui, Destroy
    Gui, +ToolWindow -Caption +AlwaysOnTop ; -DPIScale
    Gui, Color, %bGColor%
    Gui, font, s%fontSize% c%fontColor%, %fontFamily%
    Gui, Add, Text, x0 y0 w0 h%controlHight% -Wrap, ; 初始定位

    If selectText in ,%A_Space%,%A_Tab%,`r`n,`r,`n
    {
        If (winClipToggle=1)
        {
            Gui, Add, Button, x+0 yp hp -Wrap vselectAll gSelectAll, ` ` 全选` ` ` 
            Gui, Add, Button, x+0 yp hp -Wrap vpaste gPaste, ` ` 粘贴` ` ` 
        }
    }
    Else
    {
        Gui, Add, Button, x+0 yp hp -Wrap vsearch gGoogleSearch, ` 🔍` ` 
        If (linkText!="")
            Gui, Add, Button, x+0 yp hp -Wrap gLink, ` %linkButton%` ` 	
        Gui, Add, Button, x+0 yp hp -Wrap vselectAll gSelectAll, ` ` 全选` ` ` 
        If (winClipToggle=1)
        {
            Gui, Add, Button, x+0 yp hp -Wrap vcut gCut, ` ` 剪切` ` `
            Gui, Add, Button, x+0 yp hp -Wrap vcopy gCopy, ` ` 复制` ` ` 
            Gui, Add, Button, x+0 yp hp -Wrap vpaste gPaste, ` ` 粘贴` ` ` 
        }
        Else
        {
            Gui, Add, Button, x+0 yp hp -Wrap vcopy gCopy, ` ` 复制` ` ` 
        }
        Gui, Add, Button, x+0 yp hp -Wrap vaiTranslate gDeepSeekTranslate, ` ` 翻译` ` ` 
        Gui, Add, Button, x+0 yp hp -Wrap vaiAsk gDeepSeekAsk, ` ❓` ` 
        Gui, Add, Button, x+0 yp hp -Wrap vaiRewrite gDeepSeekRewrite, ` ✍` ` 
        Gui, Add, Button, x+0 yp hp -Wrap vaiGrammar gDeepSeekGrammar, ` 📝` ` 
    }

    Gui, font
    Gui, Show, NA AutoSize x%guiShowX% y%guiShowY%, %winTitle%
    WinGetPos , x, y, w, h, %winTitle%

    winMoveX:=x-w/2,0
    If (winMoveX > VirtualWidth-w+15*dpiRatio)
        winMoveX:=VirtualWidth-w+15*dpiRatio

    winMoveY:=Max(y,0)

    WinMove, %winTitle%, , winMoveX, winMoveY, w-15*dpiRatio, %winHeightPx%
}

GoogleSearch:
    Gui, Destroy
    urlEncodedText:=UriEncode(selectText)
    Run, https://www.google.com/search?ie=utf-8&oe=utf-8&q=%urlEncodedText%
Return

SelectAll:
    Gui, Destroy
    WinActivate, ahk_id %win%
    WinWaitActive, ahk_id %win%
    Send, {CtrlDown}a
    Sleep, 100
    Send, {CtrlUp}
    GetSelectText()
    ShowWinclip()
Return

Copy:
    Gui, Destroy
    WinActivate, ahk_id %win%
    WinWaitActive, ahk_id %win%
    
    ; 直接设置剪贴板内容
    Clipboard := selectText
Return

Cut:
    Gosub, Copy
    Send, {Del}
Return

Paste:
    Gui, Destroy
    WinActivate, ahk_id %win%
    WinWaitActive, ahk_id %win%
    Send, {CtrlDown}v
    Sleep, 100
    Send, {CtrlUp}
Return

Link:
    Gui, Destroy
    Try
    Run, %linkText%
Return

DeepSeekTranslate:
    Gui, Destroy
    result := DeepSeekTranslateText(selectText)
    ShowTranslationResult(result)
Return

DeepSeekTranslateText(text) {
    ; 从配置文件读取 API Key
    IniRead, apiKey, %A_ScriptDir%\config.ini, DeepSeek, apiKey
    if (apiKey = "ERROR" || apiKey = "") {
        MsgBox, 请在 config.ini 文件中正确设置您的 DeepSeek API Key`n格式：apiKey=YOUR_API_KEY
        return "请先配置 API Key"
    }
    
    ; 清理 API Key（移除可能的空白字符和换行符）
    apiKey := RegExReplace(apiKey, "[\s\r\n]+")
    if (apiKey = "") {
        MsgBox, API Key 格式不正确，请检查 config.ini 文件
        return "API Key 格式不正确"
    }
    
    ; 创建 HTTP 请求
    try {
        whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        url := "https://api.deepseek.com/v1/chat/completions"
        whr.Open("POST", url, true)
        
        ; 设置请求头
        try {
            whr.SetRequestHeader("Content-Type", "application/json; charset=utf-8")
            whr.SetRequestHeader("Authorization", "Bearer " . apiKey)
            whr.SetRequestHeader("Accept", "application/json; charset=utf-8")
        } catch e {
            return "设置请求头失败：" . e.what . " " . e.message
        }
        
        whr.Option(9) := 2048  ; 强制使用 UTF-8
        whr.Option(6) := false ; 禁用重定向
        
        ; 准备翻译提示词
        systemPrompt := "你是一个专业的翻译助手。如果输入的是中文就翻译成英文，如果输入的是英文就翻译成中文。只返回翻译结果，不要包含任何解释或其他内容。"
        
        ; 转义特殊字符
        text := StrReplace(text, "\", "\\")
        text := StrReplace(text, """", "\""")
        text := StrReplace(text, "`n", "\n")
        text := StrReplace(text, "`r", "\r")
        text := StrReplace(text, "`t", "\t")
        
        ; 准备请求数据
        postData := "{""model"":""deepseek-chat"",""messages"":[{""role"":""system"",""content"":""" . systemPrompt . """},{""role"":""user"",""content"":""" . text . """}],""temperature"":0.3}"
        
        ; 发送请求
        whr.Send(postData)
        whr.WaitForResponse()
        
        ; 获取原始响应
        responseBody := whr.ResponseBody
        ; 将响应体转换为文本
        ADO := ComObjCreate("ADODB.Stream")
        ADO.Type := 1  ; 二进制
        ADO.Mode := 3  ; 读写
        ADO.Open()
        ADO.Write(responseBody)
        ADO.Position := 0
        ADO.Type := 2  ; 文本
        ADO.Charset := "UTF-8"
        response := ADO.ReadText()
        ADO.Close()
        
        ; 检查响应状态码
        status := whr.Status
        if (status != 200) {
            return "翻译请求失败：HTTP状态码 " . status . "`n响应内容：" . response
        }
        
        ; 解析 JSON 响应
        RegExMatch(response, """content"":\s*""(.+?)""[,}]", match)
        
        if (match1) {
            ; 直接返回匹配到的内容，不做任何处理
            return match1
        } else {
            return "翻译失败，未能解析API响应：" . response
        }
    } catch e {
        return "翻译请求失败：" . e.what . " " . e.message . "`n" . e.extra
    }
}

ShowTranslationResult(text) {
    static
    
    ; 处理换行，将 \n 转换为实际换行
    text := StrReplace(text, "\n", "`n")
    
    ; 获取鼠标位置
    MouseGetPos, mouseX, mouseY
    
    ; 获取当前显示器的工作区
    SysGet, MonitorWorkArea, MonitorWorkArea
    
    ; 设置窗口大小
    windowWidth := 450  ; 固定宽度
    windowHeight := 350  ; 固定高度
    editWidth := windowWidth - 20  ; 编辑框宽度（考虑边距）
    
    ; 创建GUI
    Gui, TransResult:New
    Gui, TransResult:+AlwaysOnTop
    
    ; 设置字体
    Gui, TransResult:Font, s10, Microsoft YaHei
    
    ; 添加编辑框，启用自动换行和垂直滚动条
    Gui, TransResult:Add, Edit, x10 y10 w%editWidth% h%windowHeight% vtranslatedTextEdit ReadOnly +Multi +VScroll +Wrap, %text%
    
    ; 添加复制和关闭按钮
    buttonY := windowHeight + 10
    buttonWidth := 80
    Gui, TransResult:Add, Button, x10 y%buttonY% w%buttonWidth% gCopyTransResult, 复制
    Gui, TransResult:Add, Button, x+10 y%buttonY% w%buttonWidth% gCloseTransResult, 关闭
    
    ; 计算窗口位置
    winX := mouseX
    winY := mouseY - windowHeight - 50  ; 默认显示在鼠标上方
    
    ; 确保窗口在屏幕范围内
    if (winX + windowWidth > MonitorWorkAreaRight)
        winX := MonitorWorkAreaRight - windowWidth
    if (winX < MonitorWorkAreaLeft)
        winX := MonitorWorkAreaLeft
        
    if (winY + windowHeight + 50 > MonitorWorkAreaBottom)  ; 50是按钮区域的高度
        winY := MonitorWorkAreaBottom - windowHeight - 50
    if (winY < MonitorWorkAreaTop)
        winY := mouseY + 20  ; 如果上方放不下，就放在鼠标下方
    
    ; 显示窗口
    totalHeight := windowHeight + 45  ; 窗口总高度包括按钮区域
    Gui, TransResult:Show, x%winX% y%winY% w%windowWidth% h%totalHeight%, 结果
}

CopyTransResult:
Gui, TransResult:Submit, NoHide
GuiControlGet, Clipboard,, translatedTextEdit
Gui, TransResult:Destroy
Return

CloseTransResult:
Gui, TransResult:Destroy
Return

; from http://the-automator.com/parse-url-parameters/
UriEncode(Uri, Mode := 0, RE="[0-9A-Za-z]"){
    VarSetCapacity(Var,StrPut(Uri,"UTF-8"),0),StrPut(Uri,&Var,"UTF-8")
    While Code:=NumGet(Var,A_Index-1,"UChar")
        Res.=(Chr:=Chr(Code))~=RE?Chr:Format("%{:02X}",Code)

    Res:=StrReplace(Res, "&", "%26")
    Res:=StrReplace(Res, "`n", "%0A")
    If (Mode==1)
        Res:=StrReplace(Res, "%2F", "%5C%2F")
Return,Res
}

; 处理鼠标点击的函数
HandleMouseClick() {
    global winTitle, winClipToggle
    ; 获得鼠标当前坐标
    MouseGetPos, perPosX, perPosY
    ; 获得当前时间
    preTime:=A_TickCount
    If (A_Cursor="IBeam")
        winClipToggle:=1

    Send, {LButton Down}
    KeyWait, LButton

    Send, {LButton Up}

    If (A_Cursor="IBeam")
        winClipToggle:=1

    If !WinActive(winTitle)
    {
        win:= WinExist("A")
        ShowMainGui(perPosX,perPosY,preTime) 
    }
}

DeepSeekAsk:
    Gui, Destroy
    result := DeepSeekAskText(selectText)
    ShowTranslationResult(result)
Return

DeepSeekAskText(text) {
    ; 从配置文件读取 API Key
    IniRead, apiKey, %A_ScriptDir%\config.ini, DeepSeek, apiKey
    if (apiKey = "ERROR" || apiKey = "") {
        MsgBox, 请在 config.ini 文件中正确设置您的 DeepSeek API Key`n格式：apiKey=YOUR_API_KEY
        return "请先配置 API Key"
    }
    
    ; 清理 API Key（移除可能的空白字符和换行符）
    apiKey := RegExReplace(apiKey, "[\s\r\n]+")
    if (apiKey = "") {
        MsgBox, API Key 格式不正确，请检查 config.ini 文件
        return "API Key 格式不正确"
    }
    
    ; 创建 HTTP 请求
    try {
        whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        url := "https://api.deepseek.com/v1/chat/completions"
        whr.Open("POST", url, true)
        
        ; 设置请求头
        try {
            whr.SetRequestHeader("Content-Type", "application/json; charset=utf-8")
            whr.SetRequestHeader("Authorization", "Bearer " . apiKey)
            whr.SetRequestHeader("Accept", "application/json; charset=utf-8")
        } catch e {
            return "设置请求头失败：" . e.what . " " . e.message
        }
        
        whr.Option(9) := 2048  ; 强制使用 UTF-8
        whr.Option(6) := false ; 禁用重定向
        
        ; 准备问答提示词
        systemPrompt := "你现在是一个百科全书，请用简洁的中文解释这个问题"
        
        ; 转义特殊字符
        text := StrReplace(text, "\", "\\")
        text := StrReplace(text, """", "\""")
        text := StrReplace(text, "`n", "\n")
        text := StrReplace(text, "`r", "\r")
        text := StrReplace(text, "`t", "\t")
        
        ; 准备请求数据
        postData := "{""model"":""deepseek-chat"",""messages"":[{""role"":""system"",""content"":""" . systemPrompt . """},{""role"":""user"",""content"":""" . text . """}],""temperature"":0.3}"
        
        ; 发送请求
        whr.Send(postData)
        whr.WaitForResponse()
        
        ; 获取原始响应
        responseBody := whr.ResponseBody
        ; 将响应体转换为文本
        ADO := ComObjCreate("ADODB.Stream")
        ADO.Type := 1  ; 二进制
        ADO.Mode := 3  ; 读写
        ADO.Open()
        ADO.Write(responseBody)
        ADO.Position := 0
        ADO.Type := 2  ; 文本
        ADO.Charset := "UTF-8"
        response := ADO.ReadText()
        ADO.Close()
        
        ; 检查响应状态码
        status := whr.Status
        if (status != 200) {
            return "问答请求失败：HTTP状态码 " . status . "`n响应内容：" . response
        }
        
        ; 解析 JSON 响应
        RegExMatch(response, """content"":\s*""(.+?)""[,}]", match)
        
        if (match1) {
            ; 直接返回匹配到的内容，不做任何处理
            return match1
        } else {
            return "问答失败，未能解析API响应：" . response
        }
    } catch e {
        return "问答请求失败：" . e.what . " " . e.message . "`n" . e.extra
    }
}

DeepSeekRewrite:
    Gui, Destroy
    result := DeepSeekRewriteText(selectText)
    ShowTranslationResult(result)
Return

DeepSeekRewriteText(text) {
    ; 从配置文件读取 API Key
    IniRead, apiKey, %A_ScriptDir%\config.ini, DeepSeek, apiKey
    if (apiKey = "ERROR" || apiKey = "") {
        MsgBox, 请在 config.ini 文件中正确设置您的 DeepSeek API Key`n格式：apiKey=YOUR_API_KEY
        return "请先配置 API Key"
    }
    
    ; 清理 API Key（移除可能的空白字符和换行符）
    apiKey := RegExReplace(apiKey, "[\s\r\n]+")
    if (apiKey = "") {
        MsgBox, API Key 格式不正确，请检查 config.ini 文件
        return "API Key 格式不正确"
    }
    
    ; 创建 HTTP 请求
    try {
        whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        url := "https://api.deepseek.com/v1/chat/completions"
        whr.Open("POST", url, true)
        
        ; 设置请求头
        try {
            whr.SetRequestHeader("Content-Type", "application/json; charset=utf-8")
            whr.SetRequestHeader("Authorization", "Bearer " . apiKey)
            whr.SetRequestHeader("Accept", "application/json; charset=utf-8")
        } catch e {
            return "设置请求头失败：" . e.what . " " . e.message
        }
        
        whr.Option(9) := 2048  ; 强制使用 UTF-8
        whr.Option(6) := false ; 禁用重定向
        
        ; 准备重写提示词
        systemPrompt := "你现在是一个专业的文本重写助手。请将以下文本重写为更简洁或更丰富的表达方式。"
        
        ; 转义特殊字符
        text := StrReplace(text, "\", "\\")
        text := StrReplace(text, """", "\""")
        text := StrReplace(text, "`n", "\n")
        text := StrReplace(text, "`r", "\r")
        text := StrReplace(text, "`t", "\t")
        
        ; 准备请求数据
        postData := "{""model"":""deepseek-chat"",""messages"":[{""role"":""system"",""content"":""" . systemPrompt . """},{""role"":""user"",""content"":""" . text . """}],""temperature"":0.3}"
        
        ; 发送请求
        whr.Send(postData)
        whr.WaitForResponse()
        
        ; 获取原始响应
        responseBody := whr.ResponseBody
        ; 将响应体转换为文本
        ADO := ComObjCreate("ADODB.Stream")
        ADO.Type := 1  ; 二进制
        ADO.Mode := 3  ; 读写
        ADO.Open()
        ADO.Write(responseBody)
        ADO.Position := 0
        ADO.Type := 2  ; 文本
        ADO.Charset := "UTF-8"
        response := ADO.ReadText()
        ADO.Close()
        
        ; 检查响应状态码
        status := whr.Status
        if (status != 200) {
            return "重写请求失败：HTTP状态码 " . status . "`n响应内容：" . response
        }
        
        ; 解析 JSON 响应
        RegExMatch(response, """content"":\s*""(.+?)""[,}]", match)
        
        if (match1) {
            ; 直接返回匹配到的内容，不做任何处理
            return match1
        } else {
            return "重写失败，未能解析API响应：" . response
        }
    } catch e {
        return "重写请求失败：" . e.what . " " . e.message . "`n" . e.extra
    }
}

DeepSeekGrammar:
    Gui, Destroy
    result := DeepSeekGrammarText(selectText)
    ShowTranslationResult(result)
Return

DeepSeekGrammarText(text) {
    ; 从配置文件读取 API Key
    IniRead, apiKey, %A_ScriptDir%\config.ini, DeepSeek, apiKey
    if (apiKey = "ERROR" || apiKey = "") {
        MsgBox, 请在 config.ini 文件中正确设置您的 DeepSeek API Key`n格式：apiKey=YOUR_API_KEY
        return "请先配置 API Key"
    }
    
    ; 清理 API Key（移除可能的空白字符和换行符）
    apiKey := RegExReplace(apiKey, "[\s\r\n]+")
    if (apiKey = "") {
        MsgBox, API Key 格式不正确，请检查 config.ini 文件
        return "API Key 格式不正确"
    }
    
    ; 创建 HTTP 请求
    try {
        whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        url := "https://api.deepseek.com/v1/chat/completions"
        whr.Open("POST", url, true)
        
        ; 设置请求头
        try {
            whr.SetRequestHeader("Content-Type", "application/json; charset=utf-8")
            whr.SetRequestHeader("Authorization", "Bearer " . apiKey)
            whr.SetRequestHeader("Accept", "application/json; charset=utf-8")
        } catch e {
            return "设置请求头失败：" . e.what . " " . e.message
        }
        
        whr.Option(9) := 2048  ; 强制使用 UTF-8
        whr.Option(6) := false ; 禁用重定向
        
        ; 准备语法检查提示词
        systemPrompt := "你现在是一位专业的英语语法专家。请检查以下英文文本是否有语法错误或者是单词拼写错误。如果有错误，请直接返回修正后的文本；如果没有错误，请直接返回原文。不需要解释。待检查内容是："
        
        ; 转义特殊字符
        text := StrReplace(text, "\", "\\")
        text := StrReplace(text, """", "\""")
        text := StrReplace(text, "`n", "\n")
        text := StrReplace(text, "`r", "\r")
        text := StrReplace(text, "`t", "\t")
        
        ; 准备请求数据
        postData := "{""model"":""deepseek-chat"",""messages"":[{""role"":""system"",""content"":""" . systemPrompt . """},{""role"":""user"",""content"":""" . text . """}],""temperature"":0.1}"
        
        ; 发送请求
        whr.Send(postData)
        whr.WaitForResponse()
        
        ; 获取原始响应
        responseBody := whr.ResponseBody
        ; 将响应体转换为文本
        ADO := ComObjCreate("ADODB.Stream")
        ADO.Type := 1  ; 二进制
        ADO.Mode := 3  ; 读写
        ADO.Open()
        ADO.Write(responseBody)
        ADO.Position := 0
        ADO.Type := 2  ; 文本
        ADO.Charset := "UTF-8"
        response := ADO.ReadText()
        ADO.Close()
        
        ; 检查响应状态码
        status := whr.Status
        if (status != 200) {
            return "语法检查请求失败：HTTP状态码 " . status . "`n响应内容：" . response
        }
        
        ; 解析 JSON 响应
        RegExMatch(response, """content"":\s*""(.+?)""[,}]", match)
        
        if (match1) {
            ; 直接返回匹配到的内容，不做任何处理
            return match1
        } else {
            return "语法检查失败，未能解析API响应：" . response
        }
    } catch e {
        return "语法检查请求失败：" . e.what . " " . e.message . "`n" . e.extra
    }
} 