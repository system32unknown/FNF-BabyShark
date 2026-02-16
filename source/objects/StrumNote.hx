package objects;

import shaders.RGBPalette.RGBShaderReference;

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

		rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(strumData));
		rgbShader.enabled = false;

		useRGBShader = !(PlayState.SONG != null && PlayState.SONG.disableNoteRGB) && Settings.data.noteShaders;
		applyRGBFromSettings(strumData);

		texture = resolveSkin(); // loads frames + anims
		scrollFactor.set();
		playAnim("static");
	}

	function resolveSkin():String {
		var skin:String = Note.defaultNoteSkin;

		if (PlayState.SONG != null) {
			var s:String = PlayState.SONG.arrowSkin;
			if (s != null && s.length > 1) skin = s;
		}

		var custom:String = skin + Note.getNoteSkinPostfix();
		if (Paths.fileExists('images/$custom.png', IMAGE)) skin = custom;

		return skin;
	}

	function applyRGBFromSettings(strumData:Int):Void {
		if (strumData > PlayState.mania) return;

		var idx:Int = EK.gfxIndex[PlayState.mania][strumData];
		var arr:Array<FlxColor> = PlayState.isPixelStage ? Settings.data.arrowRGBPixelExtra[idx] : Settings.data.arrowRGBExtra[idx];

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

		var dataNum:Int = EK.gfxIndex[PlayState.mania][noteData];

		if (PlayState.isPixelStage) loadPixelAnims(dataNum);
		else loadSparrowAnims(dataNum);

		updateHitbox();
		if (lastAnim != null) playAnim(lastAnim, true);
	}

	function loadPixelAnims(dataNum:Int):Void {
		final graphic:flixel.graphics.FlxGraphic = Paths.image('pixelUI/$texture');
		loadGraphic(graphic, true, Math.floor(graphic.width / 9), Math.floor(graphic.height / 5));

		antialiasing = false;
		setGraphicSize(Std.int(width * PlayState.daPixelZoom * EK.scalesPixel[PlayState.mania]));

		animation.add('purple', [9]);
		animation.add('blue', [10]);
		animation.add('green', [11]);
		animation.add('red', [12]);
		animation.add('white', [13]);
		animation.add('yellow', [14]);
		animation.add('violet', [15]);
		animation.add('black', [16]);
		animation.add('dark', [17]);

		animation.add('static', [dataNum]);
		animation.add('pressed', [9 + dataNum, 18 + dataNum], 12, false);
		animation.add('confirm', [27 + dataNum, 36 + dataNum], 12, false);
	}

	function loadSparrowAnims(dataNum:Int):Void {
		frames = Paths.getSparrowAtlas(texture);

		animation.addByPrefix('purple', 'arrowLEFT');
		animation.addByPrefix('blue', 'arrowDOWN');
		animation.addByPrefix('green', 'arrowUP');
		animation.addByPrefix('red', 'arrowRIGHT');
		animation.addByPrefix('white', 'arrowSPACE');
		animation.addByPrefix('yellow', 'arrowLEFT');
		animation.addByPrefix('violet', 'arrowDOWN');
		animation.addByPrefix('black', 'arrowUP');
		animation.addByPrefix('dark', 'arrowRIGHT');

		antialiasing = Settings.data.antialiasing;
		setGraphicSize(Std.int(width * EK.scales[PlayState.mania]));

		var pressName:String = EK.colArray[dataNum];
		var pressNameAlt:String = EK.pressArrayAlt[dataNum];

		animation.addByPrefix('static', 'arrow' + EK.gfxDir[EK.gfxHud[PlayState.mania][noteData]]);

		// Prefer alt if exists, then fall back to normal (your original did both)
		addAnimSafe('pressed', pressNameAlt + ' press', 24, false);
		addAnimSafe('confirm', pressNameAlt + ' confirm', 24, false);

		animation.addByPrefix('pressed', pressName + ' press', 24, false);
		animation.addByPrefix('confirm', pressName + ' confirm', 24, false);
	}

	public function playerPosition():Void {
		x += EK.swidths[PlayState.mania] * noteData;
		x += 50;
		x += ((FlxG.width / 2) * player);
		x -= EK.posRest[PlayState.mania];
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

	function addAnimSafe(name:String, prefix:String, framerate:Float = 24, doLoop:Bool = true):Void {
		var animFrames:Array<flixel.graphics.frames.FlxFrame> = [];
		@:privateAccess animation.findByPrefix(animFrames, prefix); // adds valid frames to animFrames
		if (animFrames.length < 1) return;

		animation.addByPrefix(name, prefix, framerate, doLoop);
	}
}