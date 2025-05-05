package objects;

enum PopupType {
	NONE;
	RATING;
	NUMBER;
	CUSTOM(popX:Float, popY:Float, size:Float);
}

class Popup extends FlxSprite {
	public var type:PopupType;
	public var popUpTime:Float = 0;
	public static var noVelocity:Bool = false;

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

		switch (popUptype) {
			case NUMBER:
				x = placement + (43 * daloop) - 50 + comboOffset[1][0] - 43 / 2 * (Std.string(tempNotes).length - 1);
				gameCenter(Y).y += 20 - comboOffset[1][1];
				setGraphicSize(Std.int(width * (PlayState.isPixelStage ? PlayState.daPixelZoom : .5)));
			case RATING:
				x = placement - 40 + comboOffset[0][0];
				gameCenter(Y).y -= 60 + comboOffset[0][1];
				setGraphicSize(Std.int(width * (PlayState.isPixelStage ? .85 * PlayState.daPixelZoom : .7)));
			case CUSTOM(popX, popY, size):
				x = popX + comboOffset[0][0];
				y = popY + comboOffset[0][1];
				setGraphicSize(Std.int(width * size));
			case _:
		}

		updateHitbox();

		if (!noVelocity) {
			if (popUptype == RATING) {
				velocity.set(-FlxG.random.int(0, 10) * i.playbackRate + i.popupVel.x, -FlxG.random.int(140, 175) * i.playbackRate + i.popupVel.y);
				acceleration.set(i.popupAcc.x * baseRate, 550 * baseRate + i.popupAcc.y);
			} else {
				velocity.set(FlxG.random.float(-5, 5) * i.playbackRate + i.popupVel.x, -FlxG.random.int(130, 150) * i.playbackRate + i.popupVel.y);
				acceleration.set(i.popupAcc.x * baseRate, FlxG.random.int(250, 300) * baseRate + i.popupAcc.y);
			}
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