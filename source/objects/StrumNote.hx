package objects;

import shaders.RGBPalette.RGBShaderReference;

class StrumNote extends FlxSprite {
	public var rgbShader:RGBShaderReference;
	public var resetAnim:Float = 0;
	var noteData:Int = 0;
	public var direction(default, set):Float;
	public var downScroll:Bool = false;
	public var sustainReduce:Bool = true;
	public var player:Int;
	
	var _dirSin:Float;
	var _dirCos:Float;
	function set_direction(_fDir:Float):Float {
		_dirSin = Math.sin(_fDir * .01745329251);
		_dirCos = Math.cos(_fDir * .01745329251);

		return direction = _fDir;
	}

	public var texture(default, set):String = null;
	function set_texture(value:String):String {
		if(texture != value) {
			texture = value;
			reloadNote();
		}
		return value;
	}

	public var useRGBShader:Bool = true;
	public function new(x:Float, y:Float, leData:Int, player:Int) {
		direction = 90;
		animation = new backend.animation.PsychAnimationController(this);
		
		rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(leData));
		rgbShader.enabled = false;
		if(PlayState.SONG != null && PlayState.SONG.disableNoteRGB) useRGBShader = false;

		var arr:Array<FlxColor> = ClientPrefs.data.arrowRGBExtra[EK.gfxIndex[PlayState.mania][leData]];
		if(PlayState.isPixelStage) arr = ClientPrefs.data.arrowRGBPixelExtra[EK.gfxIndex[PlayState.mania][leData]];
		
		if(leData <= PlayState.mania) {
			@:bypassAccessor {
				rgbShader.r = arr[0];
				rgbShader.g = arr[1];
				rgbShader.b = arr[2];
			}
		}

		this.player = player;
		noteData = leData;
		this.ID = noteData;
		super(x, y);

		var skin:String = null;
		if(PlayState.SONG != null && PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1) skin = PlayState.SONG.arrowSkin;
		else skin = Note.defaultNoteSkin;

		var customSkin:String = skin + Note.getNoteSkinPostfix();
		if(Paths.fileExists('images/$customSkin.png', IMAGE)) skin = customSkin;

		texture = skin; //Load texture and anims
		scrollFactor.set();
		playAnim('static');
	}

	public function reloadNote() {
		var lastAnim:String = null;
		if(animation.curAnim != null) lastAnim = animation.curAnim.name;

		if(PlayState.isPixelStage) {
			loadGraphic(Paths.image('pixelUI/$texture'));
			width /= 9;
			height /= 5;
			loadGraphic(Paths.image('pixelUI/$texture'), true, Math.floor(width), Math.floor(height));

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

			var dataNum:Int = EK.gfxIndex[PlayState.mania][noteData];
			animation.add('static', [dataNum]);
			animation.add('pressed', [9 + dataNum, 18 + dataNum], 12, false);
			animation.add('confirm', [27 + dataNum, 36 + dataNum], 12, false);
		} else {
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

			antialiasing = ClientPrefs.data.antialiasing;
			setGraphicSize(Std.int(width * EK.scales[PlayState.mania]));

			var pressName:String = EK.colArray[EK.gfxIndex[PlayState.mania][noteData]];
			var pressNameAlt:String = EK.pressArrayAlt[EK.gfxIndex[PlayState.mania][noteData]];
			animation.addByPrefix('static', 'arrow' + EK.gfxDir[EK.gfxHud[PlayState.mania][noteData]]);
			attemptToAddAnimationByPrefix('pressed', pressNameAlt + ' press', 24, false);
			attemptToAddAnimationByPrefix('confirm', pressNameAlt + ' confirm', 24, false);
			animation.addByPrefix('pressed', pressName + ' press', 24, false);
			animation.addByPrefix('confirm', pressName + ' confirm', 24, false);
		}
		updateHitbox();

		if(lastAnim != null) playAnim(lastAnim, true);
	}

	public function playerPosition() {
		x += EK.swidths[PlayState.mania] * noteData;
		x += 50;
		x += ((FlxG.width / 2) * player);
		x -= EK.posRest[PlayState.mania];
	}

	override function update(elapsed:Float) {
		if(resetAnim > 0) {
			resetAnim -= elapsed;
			if(resetAnim <= 0) {
				playAnim('static');
				resetAnim = 0;
			}
		}
		super.update(elapsed);
	}

	public function playAnim(anim:String, ?force:Bool = false) {
		animation.play(anim, force);
		if(animation.curAnim != null) {
			centerOffsets();
			centerOrigin();
		}
		if(useRGBShader) rgbShader.enabled = (animation.curAnim != null && animation.curAnim.name != 'static');
	}

	function attemptToAddAnimationByPrefix(name:String, prefix:String, framerate:Float = 24, doLoop:Bool = true) {
		var animFrames:Array<flixel.graphics.frames.FlxFrame> = [];
		@:privateAccess
		animation.findByPrefix(animFrames, prefix); // adds valid frames to animFrames
		if(animFrames.length < 1) return;

		animation.addByPrefix(name, prefix, framerate, doLoop);
	}
}
