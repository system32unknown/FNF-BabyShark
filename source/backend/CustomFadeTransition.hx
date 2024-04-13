package backend;

import flixel.util.FlxAxes;
import flixel.util.FlxGradient;

class CustomFadeTransition extends MusicBeatSubstate {
	public static var finishCallback:Void->Void;
	var isTransIn:Bool = false;
	var transBlack:FlxSprite;
	var transGradient:FlxSprite;

	var duration:Float;
	var direction:FlxAxes;
	public function new(duration:Float, isTransIn:Bool, ?direction:FlxAxes = FlxAxes.X) {
		this.duration = duration;
		this.isTransIn = isTransIn;
		this.direction = direction;
		super();
	}

	override function create() {
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
		var width:Int = Std.int(FlxG.width / Math.max(camera.zoom, .001));
		var height:Int = Std.int(FlxG.height / Math.max(camera.zoom, .001));

		if (direction == FlxAxes.X) {
			transGradient = FlxGradient.createGradientFlxSprite(width, 1, (isTransIn ? [0x0, FlxColor.BLACK] : [FlxColor.BLACK, 0x0]), 1, 0);
			transGradient.scale.y = height;
			transGradient.updateHitbox();
			transGradient.scrollFactor.set();
			transGradient.screenCenter(Y);
			add(transGradient);
	
			transBlack = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
			transBlack.scale.set(width + 400, height);
			transBlack.updateHitbox();
			transBlack.scrollFactor.set();
			transBlack.screenCenter(Y);
			add(transBlack);
	
			if(isTransIn) transGradient.x = transBlack.x - transBlack.width;
			else transGradient.x = -transGradient.width;
		} else {
			transGradient = FlxGradient.createGradientFlxSprite(1, height, (isTransIn ? [0x0, FlxColor.BLACK] : [FlxColor.BLACK, 0x0]));
			transGradient.scale.x = width;
			transGradient.updateHitbox();
			transGradient.scrollFactor.set();
			transGradient.screenCenter(X);
			add(transGradient);
	
			transBlack = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
			transBlack.scale.set(width, height + 400);
			transBlack.updateHitbox();
			transBlack.scrollFactor.set();
			transBlack.screenCenter(X);
			add(transBlack);
	
			if(isTransIn) transGradient.y = transBlack.y - transBlack.height;
			else transGradient.y = -transGradient.height;
		}

		super.create();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (direction == FlxAxes.X) {
			final width:Float = FlxG.width * Math.max(camera.zoom, .001);
			final targetPos:Float = transGradient.width + 50 * Math.max(camera.zoom, .001);
			if(duration > 0) transGradient.x += (width + targetPos) * elapsed / duration;
			else transGradient.x = targetPos * elapsed;

			if(isTransIn) transBlack.x = transGradient.x + transGradient.width;
			else transBlack.x = transGradient.x - transBlack.width;

			if(transGradient.x >= targetPos) close();
		} else {
			final height:Float = FlxG.height * Math.max(camera.zoom, .001);
			final targetPos:Float = transGradient.height + 50 * Math.max(camera.zoom, .001);
			if(duration > 0) transGradient.y += (height + targetPos) * elapsed / duration;
			else transGradient.y = (targetPos) * elapsed;
	
			if(isTransIn) transBlack.y = transGradient.y + transGradient.height;
			else transBlack.y = transGradient.y - transBlack.height;
	
			if(transGradient.y >= targetPos) close();
		}
	}

	override function close() {
		super.close();

		if(finishCallback != null) {
			finishCallback();
			finishCallback = null;
		}
	}
}