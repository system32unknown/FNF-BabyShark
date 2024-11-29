package utils.system;

/**
 * Class for Windows-only functions, such as transparent windows, message boxes, and more.
 * Does not have any effect on other platforms.
 */
class NativeUtil {
	/**
	 * Allocates a new console. The console will automatically be opened
	 */
	public static function allocConsole() {
		#if windows
		PlatformUtil.allocConsole();
		PlatformUtil.clearScreen();
		#end
	}

	/**
	 * Shows a message box
	 */
	public static function showMessageBox(caption:String, message:String, icon:utils.system.PlatformUtil.MessageBoxIcon = MSG_WARNING) {
		#if windows
		PlatformUtil.showMessageBox(caption, message, icon);
		#else
		lime.app.Application.current.window.alert(message, caption);
		#end
	}

	/**
	 * Sets the console colors
	 */
	public static function setConsoleColors(foregroundColor:ConsoleColor = NONE, ?backgroundColor:ConsoleColor = NONE) {
		#if windows
		if(foregroundColor == NONE) foregroundColor = LIGHTGRAY;
		if(backgroundColor == NONE) backgroundColor = BLACK;
		PlatformUtil.setConsoleColors((cast(backgroundColor, Int) * 16) + cast(foregroundColor, Int));
		#elseif sys
		Sys.print("\x1b[0m");
		if(foregroundColor != NONE) Sys.print("\x1b[" + Std.int(consoleColorToANSI(foregroundColor)) + "m");
		if(backgroundColor != NONE) Sys.print("\x1b[" + Std.int(consoleColorToANSI(backgroundColor) + 10) + "m");
		#end
	}

	/**
	 * Switch the window's color mode to dark or light mode.
	 */
	public static function setDarkMode(title:String, enable:Bool) {
		#if windows
		if(title == null) title = lime.app.Application.current.window.title;
		PlatformUtil.setDarkMode(title, enable);
		#end
	}

	/**
	 * Forces the window header to redraw, causes a small visual jitter so use it sparingly.
	 */
	public static function redrawWindowHeader():Void {
		#if windows
		FlxG.stage.window.borderless = true;
		FlxG.stage.window.borderless = false;
		#end
	}

	public static function consoleColorToANSI(color:ConsoleColor):Int {
		return switch(color) {
			case BLACK:			30;
			case DARKBLUE:		34;
			case DARKGREEN:		32;
			case DARKCYAN:		36;
			case DARKRED:		31;
			case DARKMAGENTA:	35;
			case DARKYELLOW:	33;
			case LIGHTGRAY:		37;
			case GRAY:			90;
			case BLUE:			94;
			case GREEN:			92;
			case CYAN:			96;
			case RED:			91;
			case MAGENTA:		95;
			case YELLOW:		93;
			case WHITE | _:		97;
		}
	}
	public static function consoleColorToOpenFL(color:ConsoleColor):FlxColor {
		return switch(color) {
			case BLACK:		 0xFF000000;
			case DARKBLUE:	 0xFF000088;
			case DARKGREEN:	 0xFF008800;
			case DARKCYAN:	 0xFF008888;
			case DARKRED:	 0xFF880000;
			case DARKMAGENTA:0xFF880088;
			case DARKYELLOW: 0xFF888800;
			case LIGHTGRAY:	 0xFFBBBBBB;
			case GRAY:		 0xFF888888;
			case BLUE:		 0xFF0000FF;
			case GREEN:		 0xFF00FF00;
			case CYAN:		 0xFF00FFFF;
			case RED:		 0xFFFF0000;
			case MAGENTA:	 0xFFFF00FF;
			case YELLOW:	 0xFFFFFF00;
			case WHITE | _:	 0xFFFFFFFF;
		}
	}
}

enum abstract ConsoleColor(Int) {
	var BLACK:ConsoleColor = 0;
	var DARKBLUE:ConsoleColor = 1;
	var DARKGREEN:ConsoleColor = 2;
	var DARKCYAN:ConsoleColor = 3;
	var DARKRED:ConsoleColor = 4;
	var DARKMAGENTA:ConsoleColor = 5;
	var DARKYELLOW:ConsoleColor = 6;
	var LIGHTGRAY:ConsoleColor = 7;
	var GRAY:ConsoleColor = 8;
	var BLUE:ConsoleColor = 9;
	var GREEN:ConsoleColor = 10;
	var CYAN:ConsoleColor = 11;
	var RED:ConsoleColor = 12;
	var MAGENTA:ConsoleColor = 13;
	var YELLOW:ConsoleColor = 14;
	var WHITE:ConsoleColor = 15;

	var NONE:ConsoleColor = -1;
}