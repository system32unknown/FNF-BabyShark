package objects;

import shaders.RGBPalette.RGBShaderReference;
import utils.SpriteUtil;

class StrumNote extends FlxSprite {
	public var rgbShader:RGBShaderReference;
	public var resetAnim:Float = 0;

	public var noteData(default, null):Int;
	public var downScroll:Bool = false;
	public var sustainReduce:Bool = true;
	public var player:Int;

	var _dirSin:Float;
	var _dirCos:Float;

	public var direction(default, set):Float;
	function set_direction(_fDir:Float):Float {
		var rad:Float = flixel.math.FlxAngle.asRadians(_fDir);
		_dirSin = Math.sin(rad);
		_dirCos = Math.cos(rad);
		return direction = _fDir;
	}

	public var texture(default, set):String = null;
	function set_texture(value:String):String {
		if (texture != value) {
			texture = value;
			reloadNote();
		}
		return value;
	}

	public var useRGBShader:Bool = true;
	public function new(x:Float, y:Float, strumData:Int, player:Int) {
		direction = 90;
		animation = new backend.animation.PsychAnimationController(this);

		this.player = player;
		noteData = strumData;
		this.ID = noteData;
		super(x, y);

		rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(noteData));
		rgbShader.enabled = false;

		useRGBShader = !(PlayState.SONG != null && PlayState.SONG.disableNoteRGB) && Settings.data.noteShaders;
		applyRGBFromSettings(noteData);

		texture = resolveSkin(); // loads frames + anims
		scrollFactor.set();
		playAnim("static");
	}

	function resolveSkin():String {
		var skin:String = Note.DEFAULT_NOTE_SKIN;

		if (PlayState.SONG != null) {
			var s:String = PlayState.SONG.arrowSkin;
			if (s != null && s.length > 1) skin = s;
		}

		var custom:String = skin + Note.getNoteSkinPostfix();
		if (Paths.fileExists('images/$custom.png', IMAGE)) skin = custom;

		return skin;
	}

	function applyRGBFromSettings(strumData:Int):Void {
		var arr:Array<FlxColor> = (PlayState.isPixelStage ? Settings.data.arrowRGBPixel : Settings.data.arrowRGB)[strumData];
		if (arr == null || arr.length < 3) return;

		@:bypassAccessor {
			rgbShader.r = arr[0];
			rgbShader.g = arr[1];
			rgbShader.b = arr[2];
		}
	}

	public function reloadNote():Void {
		var lastAnim:String = null;
		if (animation.curAnim != null) lastAnim = animation.curAnim.name;

		if (PlayState.isPixelStage) loadPixelAnims(noteData);
		else loadSparrowAnims(noteData);

		updateHitbox();
		if (lastAnim != null) playAnim(lastAnim, true);
	}

	function loadPixelAnims(dataNum:Int):Void {
		final graphic:flixel.graphics.FlxGraphic = Paths.image('pixelUI/$texture');
		loadGraphic(graphic, true, Math.floor(graphic.width / 4), Math.floor(graphic.height / 5));

		antialiasing = false;
		setGraphicSize(Std.int(width * PlayState.daPixelZoom));

		animation.add('green', [6]);
		animation.add('red', [7]);
		animation.add('blue', [5]);
		animation.add('purple', [4]);
		switch (Math.abs(noteData) % 4) {
			case 0:
				animation.add('static', [0]);
				animation.add('pressed', [4, 8], 12, false);
				animation.add('confirm', [12, 16], 12, false);
			case 1:
				animation.add('static', [1]);
				animation.add('pressed', [5, 9], 12, false);
				animation.add('confirm', [13, 17], 12, false);
			case 2:
				animation.add('static', [2]);
				animation.add('pressed', [6, 10], 12, false);
				animation.add('confirm', [14, 18], 12, false);
			case 3:
				animation.add('static', [3]);
				animation.add('pressed', [7, 11], 12, false);
				animation.add('confirm', [15, 19], 12, false);
		}
	}

	function loadSparrowAnims(dataNum:Int):Void {
		frames = Paths.sparrowAtlas(texture);

		animation.addByPrefix('green', 'arrowUP');
		animation.addByPrefix('blue', 'arrowDOWN');
		animation.addByPrefix('purple', 'arrowLEFT');
		animation.addByPrefix('red', 'arrowRIGHT');

		antialiasing = Settings.data.antialiasing;
		setGraphicSize(Std.int(width * .7));
		switch (Math.abs(noteData) % 4) {
			case 0:
				animation.addByPrefix('static', 'arrowLEFT');
				animation.addByPrefix('pressed', 'left press', 24, false);
				animation.addByPrefix('confirm', 'left confirm', 24, false);
			case 1:
				animation.addByPrefix('static', 'arrowDOWN');
				animation.addByPrefix('pressed', 'down press', 24, false);
				animation.addByPrefix('confirm', 'down confirm', 24, false);
			case 2:
				animation.addByPrefix('static', 'arrowUP');
				animation.addByPrefix('pressed', 'up press', 24, false);
				animation.addByPrefix('confirm', 'up confirm', 24, false);
			case 3:
				animation.addByPrefix('static', 'arrowRIGHT');
				animation.addByPrefix('pressed', 'right press', 24, false);
				animation.addByPrefix('confirm', 'right confirm', 24, false);
		}
	}

	public function playerPosition():Void {
		x += Note.swagWidth * noteData;
		x += 50;
		x += ((FlxG.width / 2) * player);
	}

	override function update(elapsed:Float):Void {
		if (resetAnim > 0) {
			resetAnim -= elapsed;
			if (resetAnim <= 0) {
				resetAnim = 0;
				playAnim("static");
			}
		}
		super.update(elapsed);
	}

	public function playAnim(anim:String, ?force:Bool = false):Void {
		animation.play(anim, force);
		if (animation.curAnim != null) {
			centerOffsets();
			centerOrigin();
		}
		if (useRGBShader) rgbShader.enabled = (animation.curAnim != null && animation.curAnim.name != 'static');
	}
}