package utils.system;

import lime.system.System;
import utils.system.Ansi;

/**
 * Class for functions that talk to a lower level than haxe, such as message boxes, and more.
 * Some functions might not have effect on some platforms.
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
	 * Forces the window header to redraw, causes a small visual jitter so use it sparingly.
	 */
	public static function redrawWindowHeader():Void {
		#if windows
		FlxG.stage.window.borderless = true;
		FlxG.stage.window.borderless = false;
		#end
	}

	/**
	 * Can be used to check if your using a specific version of an OS (or if your using a certain OS).
	 */
	public static function hasVersion(ver:String):Bool
		return System.platformLabel.toLowerCase().indexOf(ver.toLowerCase()) != -1;

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
		if (Main.noTerminalColor) return;

		#if (windows && !hl)
		if (foregroundColor == NONE) foregroundColor = LIGHTGRAY;
		if (backgroundColor == NONE) backgroundColor = BLACK;
		PlatformUtil.setConsoleColors((cast (backgroundColor, Int) * 16) + cast (foregroundColor, Int));
		#elseif sys
		Ansi.reset();
		if (foregroundColor != NONE) Sys.print("\x1b[" + Std.int(Ansi.colorToANSI(foregroundColor)) + "m");
		if (backgroundColor != NONE) Sys.print("\x1b[" + Std.int(Ansi.colorToANSI(backgroundColor) + 10) + "m");
		#end
	}
}