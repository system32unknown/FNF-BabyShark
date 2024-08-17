package backend;

class CustomFadeTransition extends MusicBeatSubstate {
	public static var finishCallback:Void->Void;
	var isTransIn:Bool = false;
	var transBlack:FlxSprite;
	var transGradient:FlxSprite;

	var duration:Float;
	public function new(duration:Float, isTransIn:Bool) {
		this.duration = duration;
		this.isTransIn = isTransIn;
		super();
	}

	override function create() {
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
		var width:Int = Std.int(FlxG.width / Math.max(camera.zoom, .001));
		var height:Int = Std.int(FlxG.height / Math.max(camera.zoom, .001));

		transGradient = flixel.util.FlxGradient.createGradientFlxSprite(width, 1, (isTransIn ? [0x0, FlxColor.BLACK] : [FlxColor.BLACK, 0x0]), 1, 0);
		transGradient.scale.y = height;
		transGradient.updateHitbox();
		transGradient.scrollFactor.set();
		transGradient.screenCenter(Y);
		add(transGradient);

		transBlack = new FlxSprite().makeSolid(width + 400, height, FlxColor.BLACK);
		transBlack.scrollFactor.set();
		transBlack.screenCenter(Y);
		add(transBlack);

		if(isTransIn) transGradient.x = transBlack.x - transBlack.width;
		else transGradient.x = -transGradient.width;

		super.create();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		final width:Float = FlxG.width * Math.max(camera.zoom, .001);
		final targetPos:Float = transGradient.width + 50 * Math.max(camera.zoom, .001);
		if(duration > 0) transGradient.x += (width + targetPos) * elapsed / duration;
		else transGradient.x = targetPos * elapsed;

		if(isTransIn) transBlack.x = transGradient.x + transGradient.width;
		else transBlack.x = transGradient.x - transBlack.width;

		if(transGradient.x >= targetPos) close();
	}

	override function close() {
		super.close();

		if(finishCallback != null) {
			finishCallback();
			finishCallback = null;
		}
	}
}