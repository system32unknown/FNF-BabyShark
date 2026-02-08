package funkin.utils.plugins;

/**
 * A plugin which adds functionality to press `F4` to immediately transition to the main menu.
 * This is useful for debugging or if you get softlocked or something.
 */
@:nullSafety
class EvacuateDebugPlugin extends flixel.FlxBasic {
	public static function init():Void {
		FlxG.plugins.addPlugin(new EvacuateDebugPlugin());
	}

	public override function update(elapsed:Float):Void {
		super.update(elapsed);
		if (FlxG.keys.justPressed.F4) FlxG.switchState(() -> new states.MainMenuState());
	}
}