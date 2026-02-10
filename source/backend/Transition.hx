package backend;

import flixel.util.FlxAxes;
import flixel.util.FlxGradient;

class Transition extends FlxSubState {
	public static var finishCallback:Void->Void;
	var isTransIn:Bool = false;
	var direction:FlxAxes;
	var transBlack:FlxSprite;
	var transGradient:FlxSprite;

	var duration:Float;
	public function new(duration:Float, isTransIn:Bool, direction:FlxAxes = X) {
		this.duration = duration;
		this.isTransIn = isTransIn;
		this.direction = direction;
		super();
	}

	override function create() {
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		var zoom:Float = Math.max(camera.zoom, .001);
		var width:Int = Std.int(FlxG.width / zoom);
		var height:Int = Std.int(FlxG.height / zoom);

		var gradientColors:Array<Int> = isTransIn ? [0x0, FlxColor.BLACK] : [FlxColor.BLACK, 0x0];

		if (direction == X) {
			transGradient = FlxGradient.createGradientFlxSprite(width, 1, gradientColors, 1, 0);
			transGradient.scale.y = height;
			transGradient.updateHitbox();
			transGradient.gameCenter(Y);

			transBlack = new FlxSprite().makeSolid(width + 400, height, FlxColor.BLACK);
			transBlack.gameCenter(Y);

			if (isTransIn) transGradient.x = transBlack.x - transBlack.width;
			else transGradient.x = -transGradient.width;
		} else { // Y
			transGradient = FlxGradient.createGradientFlxSprite(1, height, gradientColors);
			transGradient.scale.x = width;
			transGradient.updateHitbox();
			transGradient.gameCenter(X);

			transBlack = new FlxSprite().makeSolid(width, height + 400, FlxColor.BLACK);
			transBlack.gameCenter(X);

			if (isTransIn) transGradient.y = transBlack.y - transBlack.height;
			else transGradient.y = -transGradient.height;
		}

		transGradient.scrollFactor.set();
		transBlack.scrollFactor.set();

		add(transGradient);
		add(transBlack);
		super.create();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		var zoom:Float = Math.max(camera.zoom, .001);
		var speed:Float = ((direction == X ? FlxG.width : FlxG.height) / zoom + getGradientSize() + 50) * elapsed / Math.max(duration, .0001);

		if (direction == X) {
			transGradient.x += speed;

			if (isTransIn) transBlack.x = transGradient.x + transGradient.width;
			else transBlack.x = transGradient.x - transBlack.width;

			if (transGradient.x >= getTargetPos()) close();
		} else {
			transGradient.y += speed;

			if (isTransIn) transBlack.y = transGradient.y + transGradient.height;
			else transBlack.y = transGradient.y - transBlack.height;

			if (transGradient.y >= getTargetPos()) close();
		}
	}

	inline function getGradientSize():Float {
		return direction == X ? transGradient.width : transGradient.height;
	}
	inline function getTargetPos():Float {
		return getGradientSize() + 50;
	}

	override function close() {
		super.close();

		if (finishCallback != null) {
			finishCallback();
			finishCallback = null;
		}
	}
}