package objects;

import flixel.addons.display.FlxPieDial;
#if hxvlc import hxvlc.flixel.FlxVideoSprite; #end

class VideoSprite extends FlxSpriteGroup {
	#if VIDEOS_ALLOWED
	public static var _videos:Array<VideoSprite> = [];

	public var finishCallback:Void->Void = null;
	public var onSkip:Void->Void = null;

	final _timeToSkip:Float = 1;
	public var holdingTime:Float = 0;
	public var videoSprite:FlxVideoSprite;
	public var skipSprite:FlxPieDial;
	public var cover:FlxSprite;
	public var canSkip(default, set):Bool = false;

	var videoName:String;

	public var waiting:Bool = false;
	public var isPlaying:Bool = false;
	public var isPaused:Bool = false;

	public function new(videoName:String, isWaiting:Bool, canSkip:Bool = false, shouldLoop:Dynamic = false, adjustSize:Bool = true) {
		super();

		this.videoName = videoName;
		scrollFactor.set();
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		waiting = isWaiting;
		if(!waiting) {
			cover = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
			cover.scale.set(FlxG.width + 100, FlxG.height + 100);
			cover.screenCenter();
			cover.scrollFactor.set();
			add(cover);
		}

		// initialize sprites
		videoSprite = new FlxVideoSprite();
		videoSprite.antialiasing = ClientPrefs.data.antialiasing;
		add(videoSprite);
		this.canSkip = canSkip;

		// callbacks
		if(!shouldLoop) {
			videoSprite.bitmap.onEndReached.add(() -> {
				if(alreadyDestroyed) return;

				trace('Video destroyed');
				if(cover != null) {
					remove(cover);
					cover.destroy();
				}

				psychlua.LuaUtils.getInstance().remove(this);
				destroy();
				alreadyDestroyed = true;
			});
		}

		if(adjustSize) videoSprite.bitmap.onFormatSetup.add(() -> {
			videoSprite.setGraphicSize(FlxG.width);
			videoSprite.updateHitbox();
			videoSprite.screenCenter();
		});

		// start video and adjust resolution to screen size
		videoSprite.load(this.videoName, shouldLoop ? ['input-repeat=65545'] : null);
		_videos.push(this);
	}

	var alreadyDestroyed:Bool = false;
	override function destroy() {
		if(alreadyDestroyed) {
			super.destroy();
			return;
		}

		trace('Video destroyed');
		if(cover != null) {
			remove(cover);
			cover.destroy();
		}

		if(finishCallback != null) finishCallback();
		onSkip = null;

		psychlua.LuaUtils.getInstance().remove(this);
		super.destroy();
	}

	override function update(elapsed:Float) {
		if(canSkip) {
			if(Controls.instance.pressed('accept')) holdingTime = FlxMath.bound(holdingTime + elapsed, 0, _timeToSkip);
			else if (holdingTime > 0) holdingTime = Math.max(0, FlxMath.lerp(holdingTime, -.1, FlxMath.bound(elapsed * 3, 0, 1)));
			updateSkipAlpha();

			if(holdingTime >= _timeToSkip) {
				if(onSkip != null) onSkip();
				finishCallback = null;
				videoSprite.bitmap.onEndReached.dispatch();
				psychlua.LuaUtils.getInstance().remove(this);
				trace('Skipped video');
				return;
			}
		}
		super.update(elapsed);
	}

	function set_canSkip(newValue:Bool):Bool {
		canSkip = newValue;
		if(canSkip) {
			if(skipSprite == null) {
				skipSprite = new FlxPieDial(0, 0, 40, FlxColor.WHITE, 40, true, 24);
				skipSprite.replaceColor(FlxColor.BLACK, FlxColor.TRANSPARENT);
                skipSprite.setPosition(FlxG.width - (skipSprite.width + 80), FlxG.height - (skipSprite.height + 72));
				skipSprite.amount = 0;
				add(skipSprite);
			}
		} else if(skipSprite != null) {
			remove(skipSprite);
			skipSprite.destroy();
			skipSprite = null;
		}
		return canSkip;
	}

	function updateSkipAlpha() {
		if(skipSprite == null) return;

		skipSprite.amount = Math.min(1, Math.max(0, (holdingTime / _timeToSkip) * 1.025));
		skipSprite.alpha = FlxMath.remapToRange(skipSprite.amount, .025, 1, 0, 1);
	}

	public function play() {
		isPlaying = true;
		videoSprite?.play();
	}
	public function resume() {
		isPaused = false;
		videoSprite?.resume();
	}
	public function pause() {
		isPaused = true;
		videoSprite?.pause();
	}
	#end
}