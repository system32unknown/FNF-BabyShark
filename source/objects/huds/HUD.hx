package objects.huds;

class HUD extends FlxSpriteGroup {
	public var botplay(default, set):Bool = false;
	function set_botplay(v:Bool):Bool {
		return botplay = v;
	}

	public var downscroll(default, set):Bool = false;
	function set_downscroll(v:Bool):Bool {
		// override this if you're setting y positions or something
		return downscroll = v;
	}

	public var paused(default, set):Bool;
	function set_paused(v:Bool):Bool {
		return paused = v;
	}

	var game:PlayState = PlayState.instance;

	public function healthChange(value:Float) {}
	public function songStarted() {}

  	public function updateScoreText():Void {}
  	public function updateHealthBar():Void {}

  	public function setHealthColors(one:FlxColor, ?two:FlxColor):Void {
		two ??= one;
	}
  	public function setTimeBarColors(one:FlxColor, ?two:FlxColor):Void {
		two ??= one;
	}

  	public function stepHit(step:Int):Void {}
  	public function beatHit(beat:Int):Void {}
}