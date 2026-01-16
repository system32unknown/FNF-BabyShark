package utils.plugins;

/**
 * A plugin which forcibly crashes the application.
 * TODO: Should we disable this in release builds?
 */
@:nullSafety
class ForceCrashPlugin extends flixel.FlxBasic {
	public static function init():Void {
		FlxG.plugins.addPlugin(new ForceCrashPlugin());
	}

	public override function update(elapsed:Float):Void {
		super.update(elapsed);

		// Ctrl + Alt + Shift + L = Crash the game for debugging purposes
		if (Util.allPressedWithDebounce([CONTROL, ALT, SHIFT, L])) throw "DEBUG: Crashing the game via debug keybind!";
	}
}