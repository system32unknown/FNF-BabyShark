package utils;

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

// Test
// #pragma comment(lib, "Dwmapi")
// #pragma comment(lib, "Shell32.lib")
')
#end
class PlatformUtil
{
    #if windows
	@:functionCode('
        HWND hWnd = GetActiveWindow();
        res = SetWindowLong(hWnd, GWL_EXSTYLE, GetWindowLong(hWnd, GWL_EXSTYLE) | WS_EX_LAYERED);
        if (res)
            SetLayeredWindowAttributes(hWnd, RGB(r, g, b), alpha, LWA_COLORKEY);
    ')
    #end
	static public function getWindowsTransparent(r:Int = 0, g:Int = 0, b:Int = 0, alpha:Int = 0, res:Int = 0) // Only works on windows, otherwise returns 0!
		return res;

    #if windows
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
    #end
    static public function sendWindowsNotification(title:String = "", desc:String = ""):Int
        return 0;

    #if windows
    @:functionCode('
        LPCSTR lwtitle = title.c_str();
        LPCSTR lwDesc = desc.c_str();

        return MessageBox(
            NULL,
            lwDesc,
            lwtitle,
            MB_OK
        );
    ')
    #end
    static public function sendFakeMsgBox(title:String = "", desc:String = ""):Int
        return 0;

    #if windows
	@:functionCode('
        return SetCursorPos(x, y); 
    ')
    #end
	static public function setCursorPos(x:Int = 0, y:Int = 0):Int
		return 0;

    #if windows
    @:functionCode('
        HWND window = GetActiveWindow();
        HICON smallIcon = (HICON)LoadImage(NULL, path, IMAGE_ICON, 16, 16, LR_LOADFROMFILE);
        HICON icon = (HICON)LoadImage(NULL, path, IMAGE_ICON, 0, 0, LR_LOADFROMFILE | LR_DEFAULTSIZE);
        SendMessage(window, WM_SETICON, ICON_SMALL, (LPARAM)smallIcon);
        SendMessage(window, WM_SETICON, ICON_BIG, (LPARAM)icon);
    ')
    #end
    static public function setWindowIcon(path:String) {}

    #if windows
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
    #end
    static public function getMousePos(pos:Int):Int {return 0;}

    #if windows
    @:functionCode('
        system("CLS");
        std::cout<< "" <<std::flush;
    ')
    #end
    static public function clearScreen() {}

    #if windows
    @:functionCode('
        // https://stackoverflow.com/questions/9965710/how-to-change-text-and-background-color

        HANDLE conso = GetStdHandle(STD_OUTPUT_HANDLE);
        SetConsoleTextAttribute(conso, color);
    ')
    #end
    static public function setConsoleTextColor(color:Int) {}
}