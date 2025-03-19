package objects;

enum PopupType {
	NONE;
	RATING;
	NUMBER;
}

class Popup extends FlxSprite {
	public var type:PopupType;
	public var popUpTime:Float = 0;

	var i:PlayState;
	var baseAccX:Float = 0.0;

	public function new() {
		super();
		type = NONE;
		i = PlayState.instance;
		baseAccX = i.ratingAcc.x * i.playbackRate * i.playbackRate;
	}

	var texture:Popup;

	public function reloadTexture(target:String):Popup {
		popUpTime = Conductor.songPosition;
		if (Paths.popUpFramesMap.exists(target)) {
			this.frames = Paths.popUpFramesMap.get(target);
			return this;
		} else {
			texture = cast loadGraphic(Paths.image(target));
			Paths.popUpFramesMap.set(target, this.frames);
			return texture;
		}
	}

	public function setupPopupData(popUptype:PopupType = NONE, img:String) {
		type = popUptype;
		reloadTexture(img);
		if (popUptype == RATING) setGraphicSize(Std.int(width * (PlayState.isPixelStage ? .85 * PlayState.daPixelZoom : .7)));
		else setGraphicSize(Std.int(width * (PlayState.isPixelStage ? PlayState.daPixelZoom : .5)));
		updateHitbox();

		if (popUptype == RATING) {
			velocity.set(-FlxG.random.int(0, 10) * i.playbackRate + i.ratingVel.x, -FlxG.random.int(140, 175) * i.playbackRate + i.ratingVel.y);
			acceleration.set(baseAccX, 550 * i.playbackRate * i.playbackRate + i.ratingAcc.y);
		} else {
			velocity.set(FlxG.random.float(-5, 5) * i.playbackRate + i.ratingVel.x, -FlxG.random.int(130, 150) * i.playbackRate + i.ratingVel.y);
			acceleration.set(baseAccX, FlxG.random.int(250, 300) * i.playbackRate * i.playbackRate + i.ratingAcc.y);
		}
		visible = !ClientPrefs.data.hideHud;
		antialiasing = i.popupAntialias;
	}

	public function doTween(speed:Float = .001) {
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