package funkin.objects.huds;

class HUD extends FlxSpriteGroup {
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

  	public function stepHit(step:Int) {}
  	public function beatHit(beat:Int) {}
}