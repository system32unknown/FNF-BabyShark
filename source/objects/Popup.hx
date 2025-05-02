package objects;

enum PopupType {
	NONE;
	RATING;
	NUMBER;
}
enum VelocityType {
	NONE;
	NORMAL;
	CUSTOM(velX:Float, accX:Float, velY:Float, accY:Float);
}

class Popup extends FlxSprite {
	public var type:PopupType;
	public var popUpTime:Float = 0;
	public var velType:VelocityType = NORMAL;

	final placement:Float = FlxG.width * .35;
	var i:PlayState;
	var baseRate:Float = 0.0;
	var comboOffset:Array<Array<Int>> = [];

	public function new() {
		super();
		type = NONE;
		i = PlayState.instance;
		baseRate = i.playbackRate * i.playbackRate;
		comboOffset = Settings.data.comboOffset;
	}

	public function reloadTexture(target:String):Popup {
		popUpTime = Conductor.songPosition;
		if (Paths.popUpFramesMap.exists(target)) {
			this.frames = Paths.popUpFramesMap.get(target);
			return this;
		} else {
			var texture:Popup = cast loadGraphic(Paths.image(target));
			Paths.popUpFramesMap.set(target, this.frames);
			return texture;
		}
	}

	public function setupPopupData(popUptype:PopupType = NONE, img:String, ?daloop:Int, ?tempNotes:Float) {
		type = popUptype;
		reloadTexture(img);

		if (popUptype == NUMBER) {
			x = placement + (43 * daloop) - 50 + comboOffset[1][0] - 43 / 2 * (Std.string(tempNotes).length - 1);
			gameCenter(Y).y += 20 - comboOffset[1][1];
			setGraphicSize(Std.int(width * (PlayState.isPixelStage ? PlayState.daPixelZoom : .5)));
		} else {
			x = placement - 40 + comboOffset[0][0];
			gameCenter(Y).y -= 60 + comboOffset[0][1];
			setGraphicSize(Std.int(width * (PlayState.isPixelStage ? .85 * PlayState.daPixelZoom : .7)));
		}

		updateHitbox();

		switch (velType) {
			case NORMAL:
				if (popUptype == RATING) {
					velocity.set(-FlxG.random.int(0, 10) * i.playbackRate, -FlxG.random.int(140, 175) * i.playbackRate);
					acceleration.set(baseRate, 550 * baseRate);
				} else {
					velocity.set(FlxG.random.float(-5, 5) * i.playbackRate, -FlxG.random.int(130, 150) * i.playbackRate);
					acceleration.set(baseRate, FlxG.random.int(250, 300) * baseRate);
				}
			case CUSTOM(velX, accX, velY, accY):
				velocity.set(-velX * i.playbackRate, -velY * i.playbackRate);
				acceleration.set(accX * baseRate, accY * baseRate);
			case _:
		}

		visible = !Settings.data.hideHud;
		antialiasing = i.popupAntialias;
	}

	public dynamic function doTween(speed:Float = .001) {
		FlxTween.cancelTweensOf(this);
		FlxTween.tween(this, {alpha: 0}, .2 / i.playbackRate, {onComplete: (tween:FlxTween) -> kill(), startDelay: Conductor.crochet * speed / i.playbackRate});
	}

	override public function kill() {
		type = NONE;
		super.kill();
	}

	override public function revive() {
		super.revive();
		initVars();

		acceleration.set();
		velocity.set();
		setPosition();

		alpha = 1;
		visible = true;
	}
}