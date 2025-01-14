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
    #include <chrono>
    #include <iostream>
    #include <string>
')
#elseif linux
@:cppFileCode('
    #include <stdlib.h>
    #include <stdio.h>
    #include <iostream>
    #include <string>
')
#end

class PlatformUtil {
    #if windows
    @:functionCode('
        NOTIFYICONDATA m_NID;

        memset(&m_NID, 0, sizeof(m_NID));
        m_NID.cbSize = sizeof(m_NID);
        m_NID.hWnd = GetForegroundWindow();
        m_NID.uFlags = NIF_MESSAGE | NIIF_WARNING | NIS_HIDDEN;

        m_NID.uVersion = NOTIFYICON_VERSION_4;

        if (!Shell_NotifyIcon(NIM_ADD, &m_NID)) return FALSE;
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
    #elseif linux
	@:functionCode('
        std::string cmd = "notify-send -u normal \'";
        cmd += title.c_str();
        cmd += "\' \'";
        cmd += desc.c_str();
        cmd += "\'";
        system(cmd.c_str());
    ')
	#end
    public static function sendWindowsNotification(title:String = "", desc:String = ""):Bool return false;
    
    #if windows
    @:functionCode('
        HWND window = GetActiveWindow();
        HICON smallIcon = (HICON)LoadImage(NULL, path, IMAGE_ICON, 16, 16, LR_LOADFROMFILE);
        HICON icon = (HICON)LoadImage(NULL, path, IMAGE_ICON, 0, 0, LR_LOADFROMFILE | LR_DEFAULTSIZE);
        SendMessage(window, WM_SETICON, ICON_SMALL, (LPARAM)smallIcon);
        SendMessage(window, WM_SETICON, ICON_BIG, (LPARAM)icon);
    ')
    #end
    public static function setWindowIcon(path:String) {}
    #if windows
	@:functionCode('
	    HWND window = GetActiveWindow();
        SetWindowLongPtr(window, GWL_STYLE, GetWindowLongPtr(window, GWL_STYLE) & ~WS_SYSMENU); // Remove the WS_SYSMENU style
        SetWindowPos(window, NULL, 0, 0, 0, 0, SWP_FRAMECHANGED | SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOOWNERZORDER); // Force the window to redraw
	')
    #end
	public static function removeWindowIcon() {}

    //Thanks leer lol
    #if windows
    @:functionCode('
        POINT mousePos;
        if (!GetCursorPos(&mousePos)) return 0;
    ')
    #end
    public static function getMousePos():Array<Float> return #if windows [untyped __cpp__("mousePos.x"), untyped __cpp__("mousePos.y")] #else [0, 0] #end;

    #if windows
    @:functionCode('return MessageBox(GetActiveWindow(), message, caption, icon | MB_SETFOREGROUND);')
    #end
    public static function showMessageBox(caption:String, message:String, icon:MessageBoxIcon = MSG_WARNING):Int return 0;

    #if windows
	@:functionCode('
	    if (!AllocConsole()) return;

	    freopen("CONIN$", "r", stdin);
	    freopen("CONOUT$", "w", stdout);
	    freopen("CONOUT$", "w", stderr);
	')
    #end
	public static function allocConsole() {}

    #if windows
	@:functionCode('return SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), color);')
    #end
	public static function setConsoleColors(color:Int):Bool return false;

    #if windows
	@:functionCode('
		system("CLS");
		std::cout << "" << std::flush;
	')
    #end
	public static function clearScreen() {}

    #if windows
	@:functionCode('
		int darkMode = enable ? 1 : 0;
		HWND window = FindWindowA(NULL, title.c_str());

		if (window == NULL) window = FindWindowExA(GetActiveWindow(), NULL, NULL, title.c_str()); // Look for child windows if top level aint found
		if (window == NULL) window = GetActiveWindow(); // If still not found, try to get the active window
		if (window == NULL) return;

		if (S_OK != DwmSetWindowAttribute(window, 19, &darkMode, sizeof(darkMode))) {
			DwmSetWindowAttribute(window, 20, &darkMode, sizeof(darkMode));
		}
		UpdateWindow(window);
	')
    #end
	public static function setDarkMode(title:String, enable:Bool) {}

    #if windows
	@:functionCode('
        HWND window = FindWindowA(NULL, title.c_str());
        if (window == NULL) window = FindWindowExA(GetActiveWindow(), NULL, NULL, title.c_str());
        if (window == NULL) window = GetActiveWindow();
        if (window == NULL) return;

        COLORREF finalColor;
        if (color[0] == -1 && color[1] == -1 && color[2] == -1 && color[3] == -1) { // bad fix, I know :sob:
            finalColor = 0xFFFFFFFF; // Default border
        } else if (color[3] == 0)
            finalColor = 0xFFFFFFFE; // No border (must have setBorder as true)
        else finalColor = RGB(color[0], color[1], color[2]); // Use your custom color

        if (setHeader) DwmSetWindowAttribute(window, 35, &finalColor, sizeof(COLORREF));
        if (setBorder) DwmSetWindowAttribute(window, 34, &finalColor, sizeof(COLORREF));

        UpdateWindow(window);
	')
    #end
	public static function setWindowBorderColor(title:String, color:Array<Int>, setHeader:Bool = true, setBorder:Bool = true) {}

    #if windows
	@:functionCode('
        HWND window = FindWindowA(NULL, title.c_str());
        if (window == NULL) window = FindWindowExA(GetActiveWindow(), NULL, NULL, title.c_str());
        if (window == NULL) window = GetActiveWindow();
        if (window == NULL) return;

        COLORREF finalColor;
        if (color[0] == -1 && color[1] == -1 && color[2] == -1 && color[3] == -1) { // bad fix, I know :sob:
            finalColor = 0xFFFFFFFF; // Default border
        } else finalColor = RGB(color[0], color[1], color[2]); // Use your custom color

        DwmSetWindowAttribute(window, 36, &finalColor, sizeof(COLORREF));
        UpdateWindow(window);
	')
    #end
	public static function setWindowTitleColor(title:String, color:Array<Int>) {}

    #if windows
    @:functionCode('return FindWindowA(className.c_str(), windowName.c_str()) != NULL;')
    #end
    public static function findWindow(className:String = null, windowName:String = ''):Bool return false;

    #if windows
    @:functionCode('
        HWND win = FindWindowA(NULL, winName.c_str());
        if (win == NULL) win = GetActiveWindow();

        LONG winExStyle = GetWindowLong(win, GWL_EXSTYLE);
        if (winExStyle == 0) return FALSE;

        alpha = SetWindowLong(win, GWL_EXSTYLE, winExStyle ^ WS_EX_LAYERED);
        if (alpha == 0) return FALSE;
        if (SetLayeredWindowAttributes(win, color, 0, LWA_COLORKEY) == 0) return FALSE;

        return TRUE;
    ')
    #end
    public static function setTransparency(winName:String, alpha:Int, color:Int):Bool return false;

    #if windows
	@:functionCode('		
		// Get the current time
		auto now = std::chrono::high_resolution_clock::now();
		
		// Time elapsed since the epoch is obtained as DURATION (converted to seconds)
		auto duration = now.time_since_epoch();
		auto seconds = std::chrono::duration_cast<std::chrono::duration<double>>(duration);
		
		// Returns the second as double
		return seconds.count();
	')
    #end
    public static function getNanoTime():#if cpp cpp.Float64 #else Float #end return -1;

    #if windows
    @:functionCode('return SetProcessDPIAware();')
    #end
    public static function setDPIAware():Bool return false;
}

enum abstract MessageBoxIcon(Int) {
    var MSG_ERROR:MessageBoxIcon = 0x00000010;
    var MSG_QUESTION:MessageBoxIcon = 0x00000020;
    var MSG_WARNING:MessageBoxIcon = 0x00000030;
    var MSG_INFORMATION:MessageBoxIcon = 0x00000040;
}