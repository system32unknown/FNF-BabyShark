package utils.system;

import lime.app.Application;
import lime.system.System;

#if windows
@:buildXml('
	<target id="haxe">
		<lib name="dwmapi.lib" if="windows"/>
		<lib name="shell32.lib" if="windows"/>
		<lib name="gdi32.lib" if="windows"/>
	</target>
')
@:cppFileCode('
	#include <stdlib.h>
	#include <stdio.h>
	#include <windows.h>
	#include <winuser.h> // SendMessage
	#include <wingdi.h>
	#include <dwmapi.h> // DwmSetWindowAttribute
	#include <strsafe.h> // StringCchCopy
	#include <shellapi.h> // Shell_NotifyIcon
	#include <chrono> // Chrono Counting
	#include <iostream>
	#include <thread>
	#include <string>

	const DWMWINDOWATTRIBUTE darkModeAttribute = (DWMWINDOWATTRIBUTE)20;
	const DWMWINDOWATTRIBUTE darkModeAttributeFallback = (DWMWINDOWATTRIBUTE)19; // Pre-20H1

	struct HandleData {
		DWORD pid = 0;
		HWND handle = 0;
	};

	BOOL CALLBACK findByPID(HWND handle, LPARAM lParam) {
		DWORD targetPID = ((HandleData*)lParam)->pid;
		DWORD curPID = 0;

		GetWindowThreadProcessId(handle, &curPID);
		if (targetPID != curPID || GetWindow(handle, GW_OWNER) != (HWND)0 || !IsWindowVisible(handle)) {
			return TRUE;
		}

		((HandleData*)lParam)->handle = handle;
		return FALSE;
	}

	HWND curHandle = 0;
	void getHandle() {
		if (curHandle == (HWND)0) {
			HandleData data;
			data.pid = GetCurrentProcessId();
			EnumWindows(findByPID, (LPARAM)&data);
			curHandle = data.handle;
		}
	}
')
#elseif linux
@:cppFileCode('
	#include <stdlib.h>
	#include <stdio.h>
	#include <iostream>
	#include <thread>
	#include <string>
')
#elseif mac
@:cppFileCode('
	#include <iostream>
	#include <thread>
')
#end
class PlatformUtil {
	public static function __init__():Void {
		registerDPIAware();
	}

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

	// Thanks leer lol
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

	/**
	 * Enables or disables dark mode support for the title bar.
	 * Only works on Windows.
	 * 
	 * @param enable Whether to enable or disable dark mode support.
	 * @param instant Whether to skip the transition tween.
	 */
	public static function setWindowDarkMode(enable:Bool = true, instant:Bool = false):Void {
		#if (cpp && windows)
		var success:Bool = false;
		untyped __cpp__('
			getHandle();
			if (curHandle != (HWND)0) {
				const BOOL darkMode = enable ? TRUE : FALSE;
				if (S_OK == DwmSetWindowAttribute(curHandle, darkModeAttribute, (LPCVOID)&darkMode, (DWORD)sizeof(darkMode)) || S_OK == DwmSetWindowAttribute(curHandle, darkModeAttributeFallback, (LPCVOID)&darkMode, (DWORD)sizeof(darkMode))) {
					success = true;
				}

				UpdateWindow(curHandle);
			}
		');

		if (instant && success) {
			final curBarColor:Null<FlxColor> = windowBarColor;
			windowBarColor = FlxColor.BLACK;
			windowBarColor = curBarColor;
		}
		#end
	}

	/**
	 * The color of the window title bar. If `null`, the default is used.
	 * Only works on Windows.
	 */
	public static var windowBarColor(default, set):Null<FlxColor> = null;
	public static function set_windowBarColor(value:Null<FlxColor>):Null<FlxColor> {
		#if (cpp && windows)
		final intColor:Int = Std.isOfType(value, Int) ? cast FlxColor.fromRGB(value.blue, value.green, value.red, 0) : 0xffffffff;
		untyped __cpp__('
			getHandle();
			if (curHandle != (HWND)0) {
				const COLORREF targetColor = (COLORREF)intColor;
				DwmSetWindowAttribute(curHandle, 35, (LPCVOID)&targetColor, (DWORD)sizeof(targetColor));
				UpdateWindow(curHandle);
			}
		'); // DWMWA_TEXT_COLOR is 35 because it's windows 10 and 11. if they fail then that is OK.
		#end

		return windowBarColor = value;
	}

	/**
	 * The color of the window title bar text. If `null`, the default is used.
	 * Only works on Windows.
	 */
	public static var windowTextColor(default, set):Null<FlxColor> = null;
	public static function set_windowTextColor(value:Null<FlxColor>):Null<FlxColor> {
		#if (cpp && windows)
		final intColor:Int = Std.isOfType(value, Int) ? cast FlxColor.fromRGB(value.blue, value.green, value.red, 0) : 0xffffffff;
		untyped __cpp__('
			getHandle();
			if (curHandle != (HWND)0) {
				const COLORREF targetColor = (COLORREF)intColor;
				DwmSetWindowAttribute(curHandle, 36, (LPCVOID)&targetColor, (DWORD)sizeof(targetColor));
				UpdateWindow(curHandle);
			}
		'); // DWMWA_TEXT_COLOR is 36 because it's windows 10 and 11. if they fail then that is OK.
		#end

		return windowTextColor = value;
	}

	/**
	 * The color of the window border. If `null`, the default is used.
	 * Only works on Windows.
	 */
	public static var windowBorderColor(default, set):Null<FlxColor> = null;
	public static function set_windowBorderColor(value:Null<FlxColor>):Null<FlxColor> {
		#if (cpp && windows)
		final intColor:Int = Std.isOfType(value, Int) ? cast FlxColor.fromRGB(value.blue, value.green, value.red, 0) : 0xffffffff;
		untyped __cpp__('
			getHandle();
			if (curHandle != (HWND)0) {
				const COLORREF targetColor = (COLORREF)intColor;
				DwmSetWindowAttribute(curHandle, 34, (LPCVOID)&targetColor, (DWORD)sizeof(targetColor));
				UpdateWindow(curHandle);
			}
		'); // DWMWA_BORDER_COLOR is 34 because it's windows 10 and 11. if they fail then that is OK.
		#end

		return windowBorderColor = value;
	}

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

	@:functionCode('return std::thread::hardware_concurrency();')
	public static function getCPUThreadsCount():Int return -1;

	public static function registerDPIAware():Void {
		#if (cpp && windows)
		// DPI Scaling fix for windows
		// this shouldn't be needed for other systems
		// Credit to YoshiCrafter29 for finding this function
		untyped __cpp__('
			BOOL success = SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
			if (!success) success = SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE);
			if (!success) success = SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_SYSTEM_AWARE);
			if (!success) SetProcessDPIAware();
		');
		#end
	}

	static var fixedScaling:Bool = false;
	public static function fixScaling():Void {
		if (fixedScaling) return;
		fixedScaling = true;

		#if (cpp && windows)
		final display:Null<lime.system.Display> = System.getDisplay(0);
		if (display != null) {
			final dpiScale:Float = display.dpi / 96;
			@:privateAccess Application.current.window.width = Std.int(Main.game.width * dpiScale);
			@:privateAccess Application.current.window.height = Std.int(Main.game.height * dpiScale);

			Application.current.window.x = Std.int((Application.current.window.display.bounds.width - Application.current.window.width) / 2);
			Application.current.window.y = Std.int((Application.current.window.display.bounds.height - Application.current.window.height) / 2);
		}

		untyped __cpp__('
			getHandle();
			if (curHandle != (HWND)0) {
				HDC curHDC = GetDC(curHandle);
				RECT curRect;
				GetClientRect(curHandle, &curRect);
				FillRect(curHDC, &curRect, (HBRUSH)GetStockObject(BLACK_BRUSH));
				ReleaseDC(curHandle, curHDC);
			}
		');
		#end
	}
}

enum abstract MessageBoxIcon(Int) {
	var MSG_ERROR:MessageBoxIcon = 0x00000010;
	var MSG_QUESTION:MessageBoxIcon = 0x00000020;
	var MSG_WARNING:MessageBoxIcon = 0x00000030;
	var MSG_INFORMATION:MessageBoxIcon = 0x00000040;
}
