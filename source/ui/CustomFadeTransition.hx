package ui;

import flixel.util.FlxGradient;
import utils.MathUtil;

class CustomFadeTransition extends MusicBeatSubstate {
	public static var finishCallback:Void->Void;
	private var leTween:FlxTween = null;
	public static var nextCamera:FlxCamera;
	var isTransIn:Bool = false;
	var transBlack:FlxSprite;
	var transGradient:FlxSprite;

	public function new(duration:Float, isTransIn:Bool) {
		super();

		this.isTransIn = isTransIn;
		var zoom:Float = MathUtil.boundTo(FlxG.camera.zoom, 0.05, 1);
		var width:Int = Std.int(FlxG.width / zoom);
		var height:Int = Std.int(FlxG.height / zoom);
		transGradient = FlxGradient.createGradientFlxSprite(width, 1, (isTransIn ? [0x0, FlxColor.BLACK] : [FlxColor.BLACK, 0x0]), 1, 0);
		transGradient.scale.y = height;
		transGradient.updateHitbox();
		transGradient.scrollFactor.set();
		add(transGradient);

		transBlack = new FlxSprite().makeGraphic(width + 400, 1, FlxColor.BLACK);
		transBlack.scale.y = height;
		transBlack.updateHitbox();
		transBlack.scrollFactor.set();
		add(transBlack);

		transGradient.y -= (height - FlxG.height) / 2;
		transBlack.y = transGradient.y;

		if (isTransIn) {
			transGradient.x = transBlack.x - transBlack.width;
			FlxTween.tween(transGradient, {x: transGradient.width + 50}, duration, {
				onComplete: function(twn:FlxTween) {
					close();
				}, ease: FlxEase.linear
			});
		} else {
			transGradient.x = -transGradient.width;
			transBlack.x = transGradient.x - transBlack.width + 50;
			leTween = FlxTween.tween(transGradient, {x: transGradient.width + 50}, duration, {
				onComplete: function(twn:FlxTween) {
					if(finishCallback != null) {
						finishCallback();
					}
				}, ease: FlxEase.linear
			});
		}

		if(nextCamera != null) {
			transBlack.cameras = [nextCamera];
			transGradient.cameras = [nextCamera];
		}
		nextCamera = null;
	}

	override function update(elapsed:Float) {
		if(isTransIn)
			transBlack.x = transGradient.x + transGradient.width;
		else transBlack.x = transGradient.x - transBlack.width;
		super.update(elapsed);
	}

	override function destroy() {
		if (leTween != null) {
			finishCallback();
			leTween.cancel();
		}
		super.destroy();
	}
}