package utils.system;

#if windows
@:buildXml('
<target id="haxe">
    <lib name="dwmapi.lib" if="windows"/>
    <lib name="shell32.lib" if="windows"/>
</target>
')
@:cppFileCode('
#include <direct.h>
#include <stdlib.h>
#include <stdio.h>
#include <windows.h>
#include <winuser.h>
#include <dwmapi.h> // DwmSetWindowAttribute
#include <strsafe.h> // StringCchCopy
#include <shellapi.h> // Shell_NotifyIcon
#include <iostream>
#include <string>
')
class PlatformUtil {
	@:functionCode('
        HWND hWnd = GetActiveWindow();
        alpha = SetWindowLong(hWnd, GWL_EXSTYLE, GetWindowLong(hWnd, GWL_EXSTYLE) ^ WS_EX_LAYERED);
        if (alpha) return SetLayeredWindowAttributes(hWnd, color, 0, LWA_COLORKEY);
        else return FALSE;
    ')
	public static function setWindowsTransparent(color:Int = 0, alpha:Int = 0):Bool return false;

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

        if (StringCchCopy(m_NID.szInfoTitle, sizeof(m_NID.szInfoTitle), lTitle) != S_OK) return FALSE;
        if (StringCchCopy(m_NID.szInfo, sizeof(m_NID.szInfo), lDesc) != S_OK) return FALSE;

        return Shell_NotifyIcon(NIM_MODIFY, &m_NID);
    ')
    public static function sendWindowsNotification(title:String = "", desc:String = ""):Bool return false;
    
    @:functionCode('
        HWND window = GetActiveWindow();
        HICON smallIcon = (HICON)LoadImage(NULL, path, IMAGE_ICON, 16, 16, LR_LOADFROMFILE);
        HICON icon = (HICON)LoadImage(NULL, path, IMAGE_ICON, 0, 0, LR_LOADFROMFILE | LR_DEFAULTSIZE);
        SendMessage(window, WM_SETICON, ICON_SMALL, (LPARAM)smallIcon);
        SendMessage(window, WM_SETICON, ICON_BIG, (LPARAM)icon);
    ')
    public static function setWindowIcon(path:String) {}
	@:functionCode('
	    HWND window = GetActiveWindow();
        SetWindowLongPtr(window, GWL_STYLE, GetWindowLongPtr(window, GWL_STYLE) & ~WS_SYSMENU); // Remove the WS_SYSMENU style
        SetWindowPos(window, NULL, 0, 0, 0, 0, SWP_FRAMECHANGED | SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOOWNERZORDER); // Force the window to redraw
	')
	public static function removeWindowIcon() {}

    //Thanks leer lol
    @:functionCode('
        POINT mousePos;
        if (!GetCursorPos(&mousePos)) return 0;
    ')
    public static function getMousePos():Array<Float> return [untyped __cpp__("mousePos.x"), untyped __cpp__("mousePos.y")];

    @:functionCode('return MessageBox(GetActiveWindow(), message, caption, icon | MB_SETFOREGROUND);')
    public static function showMessageBox(caption:String, message:String, icon:MessageBoxIcon = MSG_WARNING):Int return 0;

	@:functionCode('
	    if (!AllocConsole()) return;

	    freopen("CONIN$", "r", stdin);
	    freopen("CONOUT$", "w", stdout);
	    freopen("CONOUT$", "w", stderr);
	')
	public static function allocConsole() {}

	@:functionCode('return SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), color);')
	public static function setConsoleColors(color:Int):Bool return false;

	@:functionCode('
		system("CLS");
		std::cout<< "" <<std::flush;
	')
	public static function clearScreen() {}

	@:functionCode('
		int enabled = enable ? 1 : 0;

		HWND window = FindWindowA(NULL, title.c_str());
		// Look for child windows if top level arent found
		if (window == NULL) window = FindWindowExA(GetActiveWindow(), NULL, NULL, title.c_str());
		if (window != NULL) DwmSetWindowAttribute(window, type, &enabled, sizeof(enabled));
	')
	public static function setWindowAtt(title:String, type:Int, enable:Bool) {}

    @:functionCode('return FindWindowA(className.c_str(), windowName.c_str()) != NULL;')
    public static function findWindow(className:String = null, windowName:String = '') return false;

    @:functionCode('
        HWND win = FindWindowA(NULL, winName.c_str());
        if (win == NULL) return FALSE;

        LONG winExStyle = GetWindowLong(win, GWL_EXSTYLE);
        if (winExStyle == 0) return FALSE;

        if (SetWindowLong(win, GWL_EXSTYLE, winExStyle ^ WS_EX_LAYERED) == 0) return FALSE;
        if (SetLayeredWindowAttributes(win, color, 0, LWA_COLORKEY) == 0) return FALSE;

        return TRUE;
    ')
    public static function setTransparency(winName:String, color:Int):Bool return false;
}
#end

enum abstract MessageBoxIcon(Int) {
    var MSG_ERROR:MessageBoxIcon = 0x00000010;
    var MSG_QUESTION:MessageBoxIcon = 0x00000020;
    var MSG_WARNING:MessageBoxIcon = 0x00000030;
    var MSG_INFORMATION:MessageBoxIcon = 0x00000040;
}