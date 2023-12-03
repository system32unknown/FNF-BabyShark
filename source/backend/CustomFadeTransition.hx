package backend;

import openfl.display.BitmapData;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxGradient;

class CustomFadeTransition extends MusicBeatSubstate {
	public static var finishCallback:Void->Void;
	public static var nextCamera:FlxCamera;

	var leTween:FlxTween;
	var isTransIn:Bool;
	var duration:Float;
	var transBlack:FlxSprite;
	var transGradient:FlxSprite;

	var scale:Float = 0;
	var finished:Bool = false;

	public function new(duration:Float = .7, isTransIn:Bool = false) {
		this.duration = duration;
		this.isTransIn = isTransIn;
		super();

		transGradient = new FlxSprite().loadGraphic(getGradient());
		transGradient.scrollFactor.set();
		transGradient.flipX = isTransIn;
		add(transGradient);

		transBlack = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		transBlack.scrollFactor.set();
		add(transBlack);

		updateHitbox();

		camera = nextCamera != null ? nextCamera : FlxG.camera;
		nextCamera = null;
	}

	override function create() {
		super.create();

		leTween = FlxTween.tween(this, {scale: 1}, duration, {onComplete: onComplete, ease: FlxEase.linear});
	}

	function onComplete(_) {
		if (!finished && !isTransIn && finishCallback != null) finishCallback();
		finished = true;

		if (isTransIn) close();
	}

	function updateHitbox() {
		var camera:FlxCamera = camera != null ? camera : FlxG.camera;
		var width:Int = FlxG.width;
		var height:Int = FlxG.height;
		var scaleX:Float = 1;
		var scaleY:Float = 1;

		if (camera != null) {
			width = camera.width;
			height = camera.height;
			scaleX = camera.scaleX;
			scaleY = camera.scaleY;
		}
		width = Math.ceil(width / scaleX);
		height = Math.ceil(height / scaleY);

		transGradient.setGraphicSize(width, height);
		transGradient.updateHitbox();
		transGradient.x = FlxMath.remapToRange(scale, 0, 1, -width, width);

		transBlack.setGraphicSize(width, height);
		transBlack.updateHitbox();
		transBlack.x = transGradient.x + (isTransIn ? width : -width);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		updateHitbox();
	}

	override function destroy() {
		if (leTween != null) leTween.cancel();
		finished = true;
		super.destroy();
	}

	static var cachedGradient:FlxGraphic;
	static function getGradient():FlxGraphic @:privateAccess {
		if (cachedGradient != null && cachedGradient.frameCollections != null) return cachedGradient;

		var bitmap:BitmapData = FlxGradient.createGradientBitmapData(FlxG.width, 1, [FlxColor.BLACK, 0x0], 1, 0);
		cachedGradient = FlxGraphic.fromBitmapData(bitmap, false, "FadeTransitionGradient");
		cachedGradient.persist = true;

		Paths.excludeAsset("FadeTransitionGradient");
		return cachedGradient;
	}
}