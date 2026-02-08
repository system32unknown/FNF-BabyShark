package funkin.backend.animation;

class PsychAnimationController extends flixel.animation.FlxAnimationController {
	public var speedType:Bool = true;
	var speed:Float;

	public override function update(elapsed:Float):Void {
		if (_curAnim != null) {
			speed = speedType ? timeScale : FlxG.animationTimeScale;
			_curAnim.update(elapsed * speed);
		} else if (_prerotated != null) _prerotated.angle = _sprite.angle;
	}
}