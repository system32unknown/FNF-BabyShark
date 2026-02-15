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
	 * Displays a native message box dialog.
	 *
	 * On Windows, this uses the system message box implementation via `PlatformUtil`.
	 * On other platforms, it falls back to the Lime window alert dialog.
	 *
	 * @param caption The title of the message box window.
	 * @param message The body text displayed inside the message box.
	 * @param icon Optional icon type to display (Windows only).
	 */
	public static function showMessageBox(caption:String, message:String, icon:utils.system.PlatformUtil.MessageBoxIcon = MSG_WARNING):Void {
		#if windows
		PlatformUtil.showMessageBox(caption, message, icon);
		#else
		lime.app.Application.current.window.alert(message, caption);
		#end
	}

	/**
	 * Sets the console foreground and background colors using ANSI escape codes.
	 *
	 * - On Windows (non-hl targets), colors are applied using `PlatformUtil`.
	 * - On other `sys` targets, ANSI escape sequences are written directly to stdout.
	 * - If `Main.noTerminalColor` is enabled, no color changes will be applied.
	 *
	 * Passing `NONE` will:
	 * - Reset to default behavior on non-Windows platforms.
	 * - Use LIGHTGRAY (foreground) and BLACK (background) as defaults on Windows.
	 *
	 * @param foregroundColor The desired text (foreground) color.
	 * @param backgroundColor Optional background color.
	 */
	public static function setAnsiColors(foregroundColor:AnsiColor = NONE, ?backgroundColor:AnsiColor = NONE):Void {
		if (Main.noTerminalColor) return;

		#if (windows && !hl)
		if (foregroundColor == NONE) foregroundColor = LIGHTGRAY;
		if (backgroundColor == NONE) backgroundColor = BLACK;
		PlatformUtil.setAnsiColors((cast(backgroundColor, Int) * 16) + cast(foregroundColor, Int));
		#elseif sys
		Sys.print("\x1b[0m");
		if (foregroundColor != NONE) Sys.print("\x1b[" + Std.int(Ansi.colorToANSI(foregroundColor)) + "m");
		if (backgroundColor != NONE) Sys.print("\x1b[" + Std.int(Ansi.colorToANSI(backgroundColor) + 10) + "m");
		#end
	}
}