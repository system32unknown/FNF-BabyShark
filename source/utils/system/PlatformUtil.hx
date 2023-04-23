package utils.system;

#if windows
@:buildXml('
<target id="haxe">
    <lib name="dwmapi.lib" if="windows"/>
    <lib name="shell32.lib" if="windows"/>
</target>
')
@:cppFileCode('
#include <stdlib.h>
#include <stdio.h>
#include <windows.h>
#include <winuser.h>
#include <dwmapi.h>
#include <strsafe.h>
#include <shellapi.h>
#include <iostream>
#include <string>
#include <psapi.h>
')
class PlatformUtil
{
	@:functionCode('
        HWND hWnd = GetActiveWindow();
        res = SetWindowLong(hWnd, GWL_EXSTYLE, GetWindowLong(hWnd, GWL_EXSTYLE) | WS_EX_LAYERED);
        if (res)
            SetLayeredWindowAttributes(hWnd, RGB(r, g, b), alpha, LWA_COLORKEY);
    ')
	static public function getWindowsTransparent(r:Int = 0, g:Int = 0, b:Int = 0, alpha:Int = 0, res:Int = 0) return res;

	@:functionCode('
        HWND hWnd = GetActiveWindow();
        res = SetWindowLong(hWnd, GWL_EXSTYLE, GetWindowLong(hWnd, GWL_EXSTYLE) ^ WS_EX_LAYERED);
        if (res)
            SetLayeredWindowAttributes(hWnd, RGB(r, g, b), alpha, LWA_COLORKEY);
    ')
	static public function getWindowsBackward(r:Int = 0, g:Int = 0, b:Int = 0, alpha:Int = 1, res:Int = 0) return res;

    @:functionCode('
        NOTIFYICONDATA m_NID;

        memset(&m_NID, 0, sizeof(m_NID));
        m_NID.cbSize = sizeof(m_NID);
        m_NID.hWnd = GetForegroundWindow();
        m_NID.uFlags = NIF_MESSAGE | NIIF_WARNING | NIS_HIDDEN;

        m_NID.uVersion = NOTIFYICON_VERSION_4;

        if (!Shell_NotifyIcon(NIM_ADD, &m_NID))
            return FALSE;
    
        Shell_NotifyIcon(NIM_SETVERSION, &m_NID);

        m_NID.uFlags |= NIF_INFO;
        m_NID.uTimeout = 1000;
        m_NID.dwInfoFlags = NULL;

        LPCTSTR lTitle = title.c_str();
        LPCTSTR lDesc = desc.c_str();

        if (StringCchCopy(m_NID.szInfoTitle, sizeof(m_NID.szInfoTitle), lTitle) != S_OK)
            return FALSE;

        if (StringCchCopy(m_NID.szInfo, sizeof(m_NID.szInfo), lDesc) != S_OK)
            return FALSE;

        return Shell_NotifyIcon(NIM_MODIFY, &m_NID);
    ')
    static public function sendWindowsNotification(title:String = "", desc:String = ""):Int return 0;
    
	@:functionCode('return SetCursorPos(x, y);')
	static public function setCursorPos(x:Int = 0, y:Int = 0):Int return 0;

    @:functionCode('
        HWND window = GetActiveWindow();
        HICON smallIcon = (HICON)LoadImage(NULL, path, IMAGE_ICON, 16, 16, LR_LOADFROMFILE);
        HICON icon = (HICON)LoadImage(NULL, path, IMAGE_ICON, 0, 0, LR_LOADFROMFILE | LR_DEFAULTSIZE);
        SendMessage(window, WM_SETICON, ICON_SMALL, (LPARAM)smallIcon);
        SendMessage(window, WM_SETICON, ICON_BIG, (LPARAM)icon);
    ')
    static public function setWindowIcon(path:String) {}

    @:functionCode('
        POINT mousePos;

        int mousePosArray[2] = {0, 0};
        if (GetCursorPos(&mousePos)) { // retrieve the mouse position
            mousePosArray[0] = mousePos.x;
            mousePosArray[1] = mousePos.y;
        }

        if (pos == 0) {
            return mousePosArray[0];
        } else if (pos == 1) {
            return mousePosArray[1];
        } else {
            return 0;
        }
    ')
    static public function getMousePos(pos:Int):Int {return 0;}

    @:functionCode('
        int darkMode = enable ? 1 : 0;
        HWND window = GetActiveWindow();
        DwmSetWindowAttribute(window, type, &darkMode, sizeof(darkMode));
    ')
    static public function setWindowAtt(type:Int, enable:Bool) {}

    @:functionCode('MessageBox(GetActiveWindow(), message, caption, icon | MB_SETFOREGROUND); ')
    static public function showMessageBox(caption:String, message:String, icon:MessageBoxIcon = MSG_WARNING) {}

    @:functionCode('SetProcessDPIAware();')
    static public function setDPIAware() {}
}
#else
class PlatformUtil {
	static public function getWindowsTransparent(r:Int = 0, g:Int = 0, b:Int = 0, alpha:Int = 0, res:Int = 0) return 0;

	static public function getWindowsBackward(r:Int = 0, g:Int = 0, b:Int = 0, alpha:Int = 1, res:Int = 0) return 0;

    static public function sendWindowsNotification(title:String = "", desc:String = ""):Int return 0;

	static public function setCursorPos(x:Int = 0, y:Int = 0):Int return 0;

    static public function setWindowIcon(path:String) {}

    static public function getMousePos(pos:Int):Int {return 0;}

    static public function setWindowAtt(type:Int, enable:Bool) {}

    static public function showMessageBox(caption:String, message:String, icon:MessageBoxIcon = MSG_WARNING) {}

    static public function setDPIAware() {}
}
#end

@:enum abstract MessageBoxIcon(Int) {
    var MSG_ERROR:MessageBoxIcon = 0x00000010;
    var MSG_QUESTION:MessageBoxIcon = 0x00000020;
    var MSG_WARNING:MessageBoxIcon = 0x00000030;
    var MSG_INFORMATION:MessageBoxIcon = 0x00000040;
}