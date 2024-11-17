package objects;

import flixel.math.FlxRect;
import flixel.graphics.FlxGraphic;

import shaders.RGBPalette;
import shaders.RGBPalette.RGBShaderReference;

typedef EventNote = {
	strumTime:Float,
	event:String,
	value1:String,
	value2:String
}

typedef NoteSplashData = {
	disabled:Bool,
	texture:String,
	useGlobalShader:Bool, //breaks r/g/b/a but makes it copy default colors for your custom note
	useRGBShader:Bool,
	antialiasing:Bool,
	a:Float
}

class Note extends FlxSprite {
	//This is needed for the hardcoded note types to appear on the Chart Editor,
	//It's also used for backwards compatibility with 0.1 - 0.3.2 charts.
	public static final defaultNoteTypes:Array<String> = [
		'', //Always leave this one empty pls
		'Alt Animation',
		'Hey!',
		'Hurt Note',
		'GF Sing',
		'No Animation'
	];

	public var extraData:Map<String, Dynamic> = new Map<String, Dynamic>();

	public var strumTime:Float = 0;
	public var noteData:Int = 0;
	public var strum:StrumNote = null;

	public var mustPress:Bool = false;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var followed:Bool = false;

	public var wasGoodHit:Bool = false;

	public var ignoreNote:Bool = false;
	public var hitByOpponent:Bool = false;
	public var prevNote:Note;
	public var nextNote:Note;

	public var spawned:Bool = false;

	public var tail:Array<Note> = []; // for sustains
	public var parent:Note;
	public var blockHit:Bool = false; // only works for player

	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;
	public var noteType(default, set):String = null;

	public var rgbShader:RGBShaderReference;
	public static var globalRgbShaders:Array<RGBPalette> = [];
	public var inEditor:Bool = false;

	public var animSuffix:String = '';
	public var gfNote:Bool = false;
	public var earlyHitMult:Float = 1;
	public var lateHitMult:Float = 1;

	public static var SUSTAIN_SIZE:Int = 44;
	public static var defaultNoteSkin(default, never):String = 'noteSkins/NOTE_assets';

	public var noteSplashData:NoteSplashData = {
		disabled: false,
		texture: null,
		antialiasing: !PlayState.isPixelStage,
		useGlobalShader: false,
		useRGBShader: (PlayState.SONG != null) ? !(PlayState.SONG.disableNoteRGB == true) : true,
		a: ClientPrefs.data.splashAlpha
	};

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var offsetAngle:Float = 0;
	public var multAlpha:Float = 1;
	public var multSpeed(default, set):Float = 1;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;

	public var hitHealth:Float = .02;
	public var missHealth:Float = .1;
	public var rating:String = 'unknown';
	public var ratingMod:Float = 0; //9 = unknown, 0.25 = shit, 0.5 = bad, 0.75 = good, 1 = sick
	public var ratingDisabled:Bool = false;

	public var texture(default, set):String = null;

	public var noAnimation:Bool = false;
	public var noMissAnimation:Bool = false;
	public var hitCausesMiss:Bool = false;
	public var distance:Float = 2000;

	public var hitsoundDisabled:Bool = false;
	public var hitsoundChartEditor:Bool = true;

	/**
	 * Forces the hitsound to be played even if the user's hitsound volume is set to 0
	**/
	public var hitsoundForce:Bool = false;
	public var hitsoundVolume(get, default):Float = 1.0;
	function get_hitsoundVolume():Float {
		if(ClientPrefs.data.hitsoundVolume > 0)
			return ClientPrefs.data.hitsoundVolume;
		return hitsoundForce ? hitsoundVolume : 0.0;
	}
	public var hitsound:String = 'hitsounds/' + Std.string(ClientPrefs.data.hitsoundTypes).toLowerCase();

	function set_multSpeed(value:Float):Float {
		resizeByRatio(value / multSpeed);
		return multSpeed = value;
	}

	inline public function resizeByRatio(ratio:Float) { //haha funny twitter shit
		if(isSustainNote && animation.curAnim != null && !animation.curAnim.name.endsWith('end')) {
			scale.y *= ratio;
			updateHitbox();
		}
	}

	function set_texture(value:String):String {
		if(texture != value) reloadNote(value);
		return texture = value;
	}

	public function defaultRGB() {
		var arr:Array<FlxColor> = ClientPrefs.data.arrowRGBExtra[EK.gfxIndex[PlayState.mania][noteData]];
		if(PlayState.isPixelStage) arr = ClientPrefs.data.arrowRGBPixelExtra[EK.gfxIndex[PlayState.mania][noteData]];

		if (arr != null && noteData > -1) {
			rgbShader.r = arr[0];
			rgbShader.g = arr[1];
			rgbShader.b = arr[2];
		} else {
			rgbShader.r = FlxColor.RED;
			rgbShader.g = FlxColor.LIME;
			rgbShader.b = FlxColor.BLUE;
		}
	}

	function set_noteType(value:String):String {
		noteSplashData.texture = PlayState.SONG != null ? PlayState.SONG.splashSkin : 'noteSplashes';
		if (rgbShader != null && rgbShader.enabled) defaultRGB();

		if(noteData > -1 && noteType != value) {
			switch(value) {
				case 'Hurt Note':
					ignoreNote = true;

					rgbShader.r = 0xFF101010;
					rgbShader.g = FlxColor.RED;
					rgbShader.b = 0xFF990022;

					// splash data and colors
					noteSplashData.texture = 'noteSplashes-electric';

					missHealth = isSustainNote ? .25 : .1;
					hitCausesMiss = true;
					hitsound = 'cancelMenu';
					hitsoundChartEditor = false;
				case 'Alt Animation':
					animSuffix = '-alt';
				case 'No Animation':
					noAnimation = true;
					noMissAnimation = true;
				case 'GF Sing':
					gfNote = true;
			}
			if (value != null && value.length > 1) backend.NoteTypesConfig.applyNoteTypeData(this, value);
			if (hitsound != 'hitsound' && hitsoundVolume > 0) Paths.sound(hitsound); //precache new sound for being idiot-proof
			noteType = value;
		}
		return value;
	}

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?inEditor:Bool = false, ?createdFrom:Dynamic = null) {
		super();

		animation = new backend.animation.PsychAnimationController(this);

		antialiasing = ClientPrefs.data.antialiasing;
		if(createdFrom == null) createdFrom = PlayState.instance;

		if(prevNote == null) prevNote = this;

		this.prevNote = prevNote;
		isSustainNote = sustainNote;
		this.inEditor = inEditor;
		this.moves = false;

		x += (ClientPrefs.data.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X) + 50 - EK.posRest[PlayState.mania];
		y -= 2000;
		this.strumTime = strumTime;
		if(!inEditor) this.strumTime += ClientPrefs.data.noteOffset;

		this.noteData = noteData;

		if(noteData > -1) {
			rgbShader = new RGBShaderReference(this, initializeGlobalRGBShader(noteData));
			if(PlayState.SONG != null && PlayState.SONG.disableNoteRGB) rgbShader.enabled = false;
			texture = '';

			if (PlayState.mania != 0) x += EK.swidths[PlayState.mania] * (noteData % EK.keys(PlayState.mania));
			if(!isSustainNote) animation.play(EK.colArray[EK.gfxIndex[PlayState.mania][noteData]] + 'Scroll');
		}

		if(prevNote != null) prevNote.nextNote = this;

		if (isSustainNote && prevNote != null) {
			alpha = .6;
			multAlpha = .6;
			hitsoundDisabled = true;
			if(ClientPrefs.data.downScroll) flipY = true;

			offsetX += width / 2;
			copyAngle = false;

			animation.play(EK.colArray[EK.gfxIndex[PlayState.mania][noteData]] + 'holdend');
			updateHitbox();

			offsetX -= width / 2;

			if (PlayState.isPixelStage) offsetX += 30 * EK.scalesPixel[PlayState.mania];

			if (prevNote.isSustainNote) {
				prevNote.animation.play(EK.colArray[EK.gfxIndex[PlayState.mania][prevNote.noteData]] + 'hold');

				prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.05;
				if(createdFrom != null && createdFrom.songSpeed != null) prevNote.scale.y *= createdFrom.songSpeed;

				if(PlayState.isPixelStage) {
					prevNote.scale.y *= 1.19;
					prevNote.scale.y *= (6 / height); //Auto adjust note size
				}
				prevNote.updateHitbox();
			}

			if(PlayState.isPixelStage) {
				scale.y *= PlayState.daPixelZoom;
				updateHitbox();
			}
			earlyHitMult = 0;
		} else if(!isSustainNote) {
			centerOffsets();
			centerOrigin();
		}
		x += offsetX;
	}

	public static function initializeGlobalRGBShader(noteData:Int):RGBPalette {
		var dataNum:Int = EK.gfxIndex[PlayState.mania][noteData];
		if(globalRgbShaders[dataNum] == null) {
			var newRGB:RGBPalette = new RGBPalette();
			var arr:Array<FlxColor> = (!PlayState.isPixelStage ? ClientPrefs.data.arrowRGBExtra : ClientPrefs.data.arrowRGBPixelExtra)[dataNum];
			if (arr != null && noteData > -1) {
				newRGB.r = arr[0];
				newRGB.g = arr[1];
				newRGB.b = arr[2];
			} else {
				newRGB.r = FlxColor.RED;
				newRGB.g = FlxColor.LIME;
				newRGB.b = FlxColor.BLUE;
			}
			globalRgbShaders[dataNum] = newRGB;
		}
		return globalRgbShaders[dataNum];
	}

	var _lastNoteOffX:Float = 0;
	static var _lastValidChecked:String; //optimization
	public var originalHeight:Float = 6;
	public var correctionOffset:Float = 0;
	public function reloadNote(texture:String = '', postfix:String = '') {
		if(texture == null) texture = '';
		if(postfix == null) postfix = '';

		var skin:String = texture + postfix;
		if(texture.length < 1) {
			if(texture.length < 1) {
				skin = PlayState.SONG?.arrowSkin;
				if(skin == null || skin.length < 1) skin = defaultNoteSkin + postfix;
			}
		} else rgbShader.enabled = false;

		var animName:String = null;
		if(animation.curAnim != null) animName = animation.curAnim.name;

		var skinPixel:String = skin;
		var lastScaleY:Float = scale.y;
		var skinPostfix:String = getNoteSkinPostfix();
		var customSkin:String = skin + skinPostfix;
		var path:String = PlayState.isPixelStage ? 'pixelUI/' : '';
		if(customSkin == _lastValidChecked || Paths.fileExists('images/' + path + customSkin + '.png', IMAGE)) {
			skin = customSkin;
			_lastValidChecked = customSkin;
		} else skinPostfix = '';

		if(PlayState.isPixelStage) {
			if(isSustainNote) {
				var graphic:FlxGraphic = Paths.image('pixelUI/' + skinPixel + 'ENDS' + skinPostfix);
				loadGraphic(graphic, true, Math.floor(graphic.width / 9), Math.floor(graphic.height / 2));
				originalHeight = graphic.height / 2;
			} else {
				var graphic:FlxGraphic = Paths.image('pixelUI/' + skinPixel + skinPostfix);
				loadGraphic(graphic, true, Math.floor(graphic.width / 9), Math.floor(graphic.height / 5));
			}
			setGraphicSize(Std.int(width * PlayState.daPixelZoom * EK.scalesPixel[PlayState.mania]));
			loadPixelNoteAnims();
			antialiasing = false;

			if(isSustainNote) {
				offsetX += _lastNoteOffX;
				_lastNoteOffX = (width - 7) * (PlayState.daPixelZoom * EK.scalesPixel[PlayState.mania] / 2);
				offsetX -= _lastNoteOffX;
			}
		} else {
			frames = Paths.getSparrowAtlas(skin);
			loadNoteAnims();
			if(!isSustainNote) {
				centerOffsets();
				centerOrigin();
			}
		}
		if(isSustainNote) scale.y = lastScaleY;
		updateHitbox();

		if(animName != null) animation.play(animName, true);
	}

	public static function getNoteSkinPostfix():String {
		var skin:String = '';
		if(ClientPrefs.data.noteSkin != ClientPrefs.defaultData.noteSkin)
			skin = '-' + ClientPrefs.data.noteSkin.trim().toLowerCase().replace(' ', '_');
		return skin;
	}

	function loadNoteAnims() {
		if (EK.colArray[EK.gfxIndex[PlayState.mania][noteData]] == null) return;
		var playAnim:String = EK.colArray[EK.gfxIndex[PlayState.mania][noteData]];
		var playAnimAlt:String = EK.colArrayAlt[EK.gfxIndex[PlayState.mania][noteData]];
		if (isSustainNote) {
			attemptToAddAnimationByPrefix('Aholdend', 'pruple end hold', 24, true);
			attemptToAddAnimationByPrefix(playAnim + 'holdend', playAnim + ' tail0', 24, true);
			attemptToAddAnimationByPrefix(playAnim + 'hold', playAnim + ' hold0', 24, true);
			attemptToAddAnimationByPrefix(playAnim + 'holdend', playAnimAlt + ' hold end', 24, true);
			attemptToAddAnimationByPrefix(playAnim + 'hold', playAnimAlt + ' hold piece', 24, true);
			animation.addByPrefix(playAnim + 'holdend', playAnim + ' hold end', 24, true);
			animation.addByPrefix(playAnim + 'hold', playAnim + ' hold piece', 24, true);
		} else {
			attemptToAddAnimationByPrefix(playAnim + 'Scroll', playAnimAlt + '0');
			animation.addByPrefix(playAnim + 'Scroll', playAnim + '0');
		}

		setGraphicSize(Std.int(width * EK.scales[PlayState.mania]));
		updateHitbox();
	}

	function loadPixelNoteAnims() {
		if (EK.colArray[EK.gfxIndex[PlayState.mania][noteData]] == null) return;
		var playAnim:String = EK.colArray[EK.gfxIndex[PlayState.mania][noteData]];
		var noteIndex:Int = EK.gfxIndex[PlayState.mania][noteData];
		if(isSustainNote) {
			animation.add(playAnim + 'holdend', [noteIndex + 9], 12, true);
			animation.add(playAnim + 'hold', [noteIndex], 12, true);
		} else animation.add(playAnim + 'Scroll', [noteIndex + 9], 12, true);
	}

	function attemptToAddAnimationByPrefix(name:String, prefix:String, framerate:Float = 24, doLoop:Bool = true) {
		var animFrames:Array<flixel.graphics.frames.FlxFrame> = [];
		@:privateAccess
		animation.findByPrefix(animFrames, prefix); // adds valid frames to animFrames
		if(animFrames.length < 1) return;

		animation.addByPrefix(name, prefix, framerate, doLoop);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		followed = false;

		if (mustPress) {
			canBeHit = (strumTime > Conductor.songPosition - (Conductor.safeZoneOffset * lateHitMult) && strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult));
			if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit) tooLate = true;
		} else {
			canBeHit = false;

			if (!wasGoodHit && strumTime <= Conductor.songPosition) {
				if(!isSustainNote || (prevNote.wasGoodHit && !ignoreNote)) wasGoodHit = true;
			}
		}

		if (tooLate && !inEditor && alpha > .3) alpha = .3;
	}

	override function destroy() {
		super.destroy();
		_lastValidChecked = '';
	}

	public function followStrumNote(songSpeed:Float = 1) {
		if (followed) return;
		var strumX:Float = strum.x;
		var strumY:Float = strum.y;
		var strumAngle:Float = strum.angle;
		var strumAlpha:Float = strum.alpha;
		var strumDirection:Float = strum.direction;

		distance = (.45 * (Conductor.songPosition - strumTime) * songSpeed * multSpeed);
		if(!strum.downScroll) distance *= -1;

		if(copyAngle) angle = strumDirection - 90 + strumAngle + offsetAngle;

		if(copyAlpha) alpha = strumAlpha * multAlpha;
		if(copyX) @:privateAccess x = strumX + offsetX + strum._dirCos * distance;
		if(copyY) {
			@:privateAccess y = strumY + offsetY + correctionOffset + strum._dirSin * distance;
			if(strum.downScroll && isSustainNote) {
				if(PlayState.isPixelStage) y -= PlayState.daPixelZoom * EK.scalesPixel[PlayState.mania] * 9.5;
				y -= (frameHeight * scale.y) - (EK.swidths[PlayState.mania] / 2);
			}
		}
		followed = true;
	}

	public function clipToStrumNote() {
		final center:Float = strum.y + offsetY + EK.swidths[PlayState.mania] / 2;
		if((mustPress || !ignoreNote) && (wasGoodHit || hitByOpponent || (prevNote.wasGoodHit && !canBeHit))) {
			final swagRect:FlxRect = clipRect ?? FlxRect.get(0, 0, frameWidth, frameHeight);
			if (strum.downScroll) {
				if(y - offset.y * scale.y + height >= center) {
					swagRect.width = frameWidth;
					swagRect.height = (center - y) / scale.y;
					swagRect.y = frameHeight - swagRect.height;
				}
			} else if (y + offset.y * scale.y <= center) {
				swagRect.y = (center - y) / scale.y;
				swagRect.width = width / scale.x;
				swagRect.height = (height / scale.y) - swagRect.y;
			}
			clipRect = swagRect;
		}
	}

	@:noCompletion override function set_clipRect(rect:FlxRect):FlxRect {
		clipRect = rect;
		frame = frames?.frames[animation.frameIndex];
		return rect;
	}

	override function kill() {
		active = visible = false;
		super.kill();
	}
}