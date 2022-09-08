package utils;

import utils.Controls;
import flixel.FlxG;

class PlayerSettings
{
	static public var player(default, null):PlayerSettings;

	public var id(default, null):Int;

	#if (haxe >= "4.0.0")
	public final controls:Controls;
	#else
	public var controls:Controls;
	#end

	function new(scheme)
	{
		this.controls = new Controls('player', scheme);
	}

	public function setKeyboardScheme(scheme)
	{
		controls.setKeyboardScheme(scheme);
	}

	static public function init():Void {
		if (player == null) {
			player = new PlayerSettings(Solo);
		}
	}

	static public function reset() {
		player = null;
	}
}