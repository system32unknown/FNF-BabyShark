package utils;

class PlayerSettings
{
	static public var player(default, null):PlayerSettings;

	#if (haxe >= "4.0.0")
	public final controls:Controls;
	#else
	public var controls:Controls;
	#end

	function new(scheme) {
		this.controls = new Controls('player', scheme);
	}

	static public function init():Void {
		if (player == null) player = new PlayerSettings(Solo);
	}
}