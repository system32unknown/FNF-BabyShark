package utils;

import Controls;
import flixel.FlxG;
import flixel.util.FlxSignal;

class PlayerSettings
{
	static public var player(default, null):PlayerSettings;

	#if (haxe >= "4.0.0")
	static public final onAvatarAdd = new FlxTypedSignal<PlayerSettings->Void>();
	static public final onAvatarRemove = new FlxTypedSignal<PlayerSettings->Void>();
	#else
	static public var onAvatarAdd = new FlxTypedSignal<PlayerSettings->Void>();
	static public var onAvatarRemove = new FlxTypedSignal<PlayerSettings->Void>();
	#end

	public var id(default, null):Int;

	#if (haxe >= "4.0.0")
	public final controls:Controls;
	#else
	public var controls:Controls;
	#end

	function new(id, scheme)
	{
		this.id = id;
		this.controls = new Controls('player$id', scheme);
	}

	public function setKeyboardScheme(scheme)
	{
		controls.setKeyboardScheme(scheme);
	}

	static public function init():Void {
		if (player == null) {
			player = new PlayerSettings(0, Solo);
		}

		var numGamepads = FlxG.gamepads.numActiveGamepads;
		if (numGamepads > 0) {
			var gamepad = FlxG.gamepads.getByID(0);
			if (gamepad == null)
				throw 'Unexpected null gamepad. id:0';

			player.controls.addDefaultGamepad(0);
		}
	}

	static public function reset() {
		player = null;
	}
}