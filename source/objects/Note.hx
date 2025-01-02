package objects;

import flixel.math.FlxRect;
import flixel.graphics.FlxGraphic;

import shaders.RGBPalette;
import shaders.RGBPalette.RGBShaderReference;

import backend.NoteLoader;

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
	useNoteRGB:Bool,
	antialiasing:Bool,
	r:FlxColor,
	g:FlxColor,
	b:FlxColor,
	a:Float
}

typedef CastNote = {
	strumTime:Float,
	// noteData and flags
	// 1st-8th bits are for noteData (256keys)
	// 9th bit is for mustHit
	// 10th bit is for isHold
	// 11th bit is for isHoldEnd
	// 12th bit is for gfNote
	// 13th bit is for altAnim
	// 14th bit is for noAnim
	// 15th bit is for noMissAnim
	// 16th bit is for blockHit
	noteData:Int,
	noteType:String,
	holdLength:Null<Float>,
	noteSkin:String
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

	public static final DEFAULT_CAST:CastNote = {
		strumTime: 0,
		noteData: 0,
		noteType: "",
		holdLength: 0,
		noteSkin: ""
	};

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
	public var sustainScale:Float = 1.0;
	public var isSustainNote:Bool = false;
	public var isSustainEnds:Bool = false;
	public var noteType(default, set):String = null;

	public var rgbShader:RGBShaderReference;
	public static var globalRgbShaders:Array<RGBPalette> = [];
	public var inEditor:Bool = false;

	public var animSuffix:String = '';
	public var gfNote:Bool = false;
	public var earlyHitMult:Float = 1;
	public var lateHitMult:Float = 1;

	public static var SUSTAIN_SIZE:Int = 44;
	public static var originalWidth:Float = 160 * .7;
	public static var originalHeight:Float = 160 * .7;
	public static var defaultNoteSkin(default, never):String = 'noteSkins/NOTE_assets';

	public var noteSplashData:NoteSplashData = {
		disabled: false,
		texture: null,
		antialiasing: !PlayState.isPixelStage,
		useGlobalShader: false,
		useRGBShader: (PlayState.SONG != null) ? !(PlayState.SONG.disableNoteRGB == true) : true,
		useNoteRGB: true,
		r: -1,
		g: -1,
		b: -1,
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
		if (ClientPrefs.data.hitsoundVolume > 0)
			return ClientPrefs.data.hitsoundVolume;
		return hitsoundForce ? hitsoundVolume : 0.0;
	}
	public var hitsound:String = 'hitsounds/' + Std.string(ClientPrefs.data.hitsoundTypes).toLowerCase();

	function set_multSpeed(value:Float):Float {
		resizeByRatio(value / multSpeed);
		return multSpeed = value;
	}

	inline public function resizeByRatio(ratio:Float) { //haha funny twitter shit
		if (isSustainNote && animation != null && animation.curAnim != null && !animation.curAnim.name.endsWith('end')) {
			scale.y *= ratio;
			updateHitbox();
		}
	}

	function set_texture(value:String):String {
		if (value == null || value.length == 0) value = defaultNoteSkin + getNoteSkinPostfix();
		if (!PlayState.isPixelStage) {
			if (texture != value) {
				if (!NoteLoader.noteSkinFramesMap.exists(value)) inline NoteLoader.initNote(value);
				frames = NoteLoader.noteSkinFramesMap.get(value);
				animation.copyFrom(NoteLoader.noteSkinAnimsMap.get(value));
				antialiasing = ClientPrefs.data.antialiasing;
				setGraphicSize(Std.int(width * EK.scales[PlayState.mania]));
				updateHitbox();
				originalWidth = width;
				originalHeight = height;
			} else return value;
		} else reloadNote(value);
		texture = value;
		return value;
	}

	public function defaultRGB() {
		var arr:Array<FlxColor> = ClientPrefs.data.arrowRGBExtra[EK.gfxIndex[PlayState.mania][noteData]];
		if (PlayState.isPixelStage) arr = ClientPrefs.data.arrowRGBPixelExtra[EK.gfxIndex[PlayState.mania][noteData]];

		if (arr != null && noteData > -1) rgbShader.setRGB(arr[0], arr[1], arr[2]);
		else rgbShader.setRGB(FlxColor.RED, FlxColor.LIME, FlxColor.BLUE);
	}

	function set_noteType(value:String):String {
		noteSplashData.texture = PlayState.SONG != null ? PlayState.SONG.splashSkin : 'noteSplashes/noteSplashes';
		if (rgbShader != null && rgbShader.enabled) defaultRGB();

		if (noteData > -1 && noteType != value) {
			switch(value) {
				case 'Hurt Note':
					ignoreNote = true;

					// splash data and colors
					rgbShader.setRGB(0xFF101010, FlxColor.RED, 0xFF990022);

					noteSplashData.r = 0xFFFF0000;
					noteSplashData.g = 0xFF101010;
					noteSplashData.texture = 'noteSplashes/noteSplashes-electric';

					missHealth = isSustainNote ? .25 : .1;
					hitCausesMiss = true;
					hitsound = 'cancelMenu';
					hitsoundChartEditor = false;
			}
			if (value != null && value.length > 1) backend.NoteTypesConfig.applyNoteTypeData(this, value);
			if (hitsound != 'hitsound' && hitsoundVolume > 0) Paths.sound(hitsound); //precache new sound for being idiot-proof
			noteType = value;
		}
		return value;
	}

	public function new() {
		super();

		animation = new backend.animation.PsychAnimationController(this);
		antialiasing = ClientPrefs.data.antialiasing;

		x += (ClientPrefs.data.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X) + 50 - EK.posRest[PlayState.mania];
		y -= 2000;

		rgbShader = new RGBShaderReference(this, initializeGlobalRGBShader(noteData));
		if (PlayState.SONG != null && PlayState.SONG.disableNoteRGB) rgbShader.enabled = false;
	}

	public static function initializeGlobalRGBShader(noteData:Int):RGBPalette {
		var dataNum:Int = EK.gfxIndex[PlayState.mania][noteData];
		if (globalRgbShaders[dataNum] == null) {
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
	public var pixelHeight:Float = 6;
	public var correctionOffset:Float = 0; //dont mess with this
	public function reloadNote(texture:String = '', postfix:String = '') {
		if (texture == null) texture = '';
		if (postfix == null) postfix = '';

		var skin:String = texture + postfix;
		if (texture.length < 1) {
			skin = PlayState.SONG?.arrowSkin;
			if (skin == null || skin.length < 1) skin = defaultNoteSkin + postfix;
		} else rgbShader.enabled = false;

		var animName:String = null;
		if (animation.curAnim != null) animName = animation.curAnim.name;

		var path = PlayState.isPixelStage ? 'pixelUI/' : '';
		var skinPixel = path + skin;
		var lastScaleY:Float = scale.y;
		var skinPostfix:String = getNoteSkinPostfix();
		var customSkin:String = skin + skinPostfix;
		if (customSkin == _lastValidChecked || Paths.fileExists('images/' + path + customSkin + '.png', IMAGE)) {
			skin = customSkin;
			_lastValidChecked = customSkin;
		} else skinPostfix = '';

		if (PlayState.isPixelStage) {
			if (isSustainNote) {
				var graphic:FlxGraphic = Paths.image(skinPixel + 'ENDS' + skinPostfix);
				loadGraphic(graphic, true, Math.floor(graphic.width / 9), Math.floor(graphic.height / 2));
				pixelHeight = graphic.height / 2;
			} else {
				var graphic:FlxGraphic = Paths.image(skinPixel + skinPostfix);
				loadGraphic(graphic, true, Math.floor(graphic.width / 9), Math.floor(graphic.height / 5));
			}
			setGraphicSize(Std.int(width * PlayState.daPixelZoom * EK.scalesPixel[PlayState.mania]));
			loadPixelNoteAnims();
			antialiasing = false;

			if (isSustainNote) {
				offsetX += _lastNoteOffX;
				_lastNoteOffX = (width - 7) * (PlayState.daPixelZoom * EK.scalesPixel[PlayState.mania] / 2);
				offsetX -= _lastNoteOffX;
			}
		} else {
			frames = Paths.getSparrowAtlas(skin);
			loadNoteAnims();
			if (!isSustainNote) {
				centerOffsets();
				centerOrigin();
			}
		}
		if (isSustainNote) scale.y = lastScaleY;
		updateHitbox();

		if (animName != null) animation.play(animName, true);
	}

	public static function getNoteSkinPostfix():String {
		var skin:String = '';
		if (ClientPrefs.data.noteSkin != ClientPrefs.defaultData.noteSkin)
			skin = '-' + ClientPrefs.data.noteSkin.trim().toLowerCase().replace(' ', '_');
		return skin;
	}

	function loadNoteAnims() {
		var gfx:Int = EK.gfxIndex[PlayState.mania][noteData];
		if (EK.colArray[gfx] == null) return;

		var playAnim:String = EK.colArray[gfx];
		var playAnimAlt:String = EK.colArrayAlt[gfx];
		if (isSustainNote) {
			addByPrefixCheck('Aholdend', 'pruple end hold');
			addByPrefixCheck(playAnim + 'holdend', playAnim + ' tail0');
			addByPrefixCheck(playAnim + 'hold', playAnim + ' hold0');
			addByPrefixCheck(playAnim + 'holdend', playAnimAlt + ' hold end');
			addByPrefixCheck(playAnim + 'hold', playAnimAlt + ' hold piece');
			animation.addByPrefix(playAnim + 'holdend', playAnim + ' hold end');
			animation.addByPrefix(playAnim + 'hold', playAnim + ' hold piece');
		} else {
			addByPrefixCheck(playAnim + 'Scroll', playAnimAlt + '0');
			animation.addByPrefix(playAnim + 'Scroll', playAnim + '0');
		}

		setGraphicSize(Std.int(width * EK.scales[PlayState.mania]));
		updateHitbox();
	}

	function loadPixelNoteAnims() {
		var gfx:Int = EK.gfxIndex[PlayState.mania][noteData];
		if (EK.colArray[gfx] == null) return;

		var playAnim:String = EK.colArray[gfx];
		if (isSustainNote) {
			animation.add(playAnim + 'holdend', [gfx + 9], 12, true);
			animation.add(playAnim + 'hold', [gfx], 12, true);
		} else animation.add(playAnim + 'Scroll', [gfx + 9], 12, true);
	}

	function addByPrefixCheck(name:String, prefix:String, framerate:Float = 24, doLoop:Bool = true) {
		var animFrames:Array<flixel.graphics.frames.FlxFrame> = [];
		@:privateAccess
		animation.findByPrefix(animFrames, prefix); // adds valid frames to animFrames
		if (animFrames.length < 1) return;
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
				if (!isSustainNote || (prevNote.wasGoodHit && !ignoreNote)) wasGoodHit = true;
			}
		}

		if (tooLate && !inEditor && alpha > .3) alpha = .3;
	}

	override public function destroy() {
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

		if (isSustainNote) {
			flipY = ClientPrefs.data.downScroll;
			scale.y = (animation != null && animation.curAnim != null && animation.curAnim.name.endsWith('end') ? 1 : Conductor.stepCrochet * .0105 * (songSpeed * multSpeed) * sustainScale);
			if (PlayState.isPixelStage) {
				scale.x = PlayState.daPixelZoom * EK.scalesPixel[PlayState.mania];
				scale.y *= PlayState.daPixelZoom * 1.19;
			}
			updateHitbox();
		}

		distance = (.45 * (Conductor.songPosition - strumTime) * songSpeed * multSpeed);
		if (!strum.downScroll) distance *= -1;

		if (copyAngle) angle = strumDirection - 90 + strumAngle + offsetAngle;
		if (copyAlpha) alpha = strumAlpha * multAlpha;

		if (copyX) @:privateAccess x = strumX + offsetX + strum._dirCos * distance;
		if (copyY) {
			@:privateAccess y = strumY + offsetY + correctionOffset + strum._dirSin * distance;
			if (strum.downScroll && isSustainNote) {
				if (PlayState.isPixelStage) y -= PlayState.daPixelZoom * EK.scalesPixel[PlayState.mania] * 9.5;
				y -= (frameHeight * scale.y) - (EK.swidths[PlayState.mania] / 2);
			}
		}
		followed = true;
	}

	public function clipToStrumNote() {
		if ((mustPress || !ignoreNote) && (wasGoodHit || hitByOpponent || (prevNote.wasGoodHit && !canBeHit))) {
			final center:Float = strum.y + offsetY + EK.swidths[PlayState.mania] / 2;
			final swagRect:FlxRect = clipRect ?? FlxRect.get(0, 0, frameWidth, frameHeight);
			if (strum.downScroll) {
				if (y - offset.y * scale.y + height >= center) {
					swagRect.y = frameHeight - swagRect.height;
					swagRect.height = (center - y) / scale.y;
				}
			} else if (y + offset.y * scale.y <= center) {
				swagRect.y = (center - y) / scale.y;
				swagRect.height = frameHeight - swagRect.y;
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

	var initSkin:String = defaultNoteSkin + getNoteSkinPostfix();
	public function recycleNote(target:CastNote, ?oldNote:Note):Note {
		var ekScale:Float = EK.scales[PlayState.mania];
		var ekScalePixel:Float = EK.scalesPixel[PlayState.mania];

		wasGoodHit = hitByOpponent = tooLate = canBeHit = spawned = followed = false; // Don't make an update call of this for the note group
		exists = true;

		multSpeed = 1;
		strumTime = target.strumTime;
		if (!inEditor) strumTime += ClientPrefs.data.noteOffset;

		mustPress = CoolUtil.toBool(target.noteData & (1 << 8));						 // mustHit
		isSustainNote = hitsoundDisabled = CoolUtil.toBool(target.noteData & (1 << 9));  // isHold
		isSustainEnds = CoolUtil.toBool(target.noteData & (1 << 10));					 // isHoldEnd
		gfNote = CoolUtil.toBool(target.noteData & (1 << 11));							 // gfNote
		animSuffix = CoolUtil.toBool(target.noteData & (1 << 12)) ? "-alt" : "";		 // altAnim
		noAnimation = noMissAnimation = CoolUtil.toBool(target.noteData & (1 << 13));	 // noAnim
		blockHit = CoolUtil.toBool(target.noteData & (1 << 15));				 		 // blockHit
		noteData = target.noteData & PlayState.mania;

		// Absoluty should be here, or messing pixel texture glitches...
		if (!PlayState.isPixelStage) {
			if (target.noteSkin == null || target.noteSkin.length == 0 && texture != initSkin) texture = initSkin;
			else if (target.noteSkin.length > 0 && target.noteSkin != texture) texture = target.noteSkin;
		} else reloadNote(texture);

		var colorRef:RGBPalette = inline initializeGlobalRGBShader(noteData);
		rgbShader.copyFromPalette(colorRef);

		if (Std.isOfType(target.noteType, String)) noteType = target.noteType; // applying note color on damage notes
		else noteType = defaultNoteTypes[Std.parseInt(target.noteType)];

		if (PlayState.SONG != null && PlayState.SONG.disableNoteRGB) rgbShader.enabled = false;
		sustainLength = target.holdLength ?? 0;
		prevNote = oldNote ?? this;

		copyAngle = !isSustainNote;
		flipY = ClientPrefs.data.downScroll && isSustainNote;
		animation.play(EK.colArray[EK.gfxIndex[PlayState.mania][noteData]] + 'Scroll', true);
		correctionOffset = isSustainNote ? (flipY ? -originalHeight * 0.5 : originalHeight * 0.5) : 0;

		if (PlayState.isPixelStage) offsetX = -5;
		if (isSustainNote) {
			alpha = multAlpha = .6;
			offsetX += width / 2;
			animation.play(EK.colArray[EK.gfxIndex[PlayState.mania][noteData]] + (isSustainEnds ? 'holdend' : 'hold'));
			updateHitbox();
			offsetX -= width / 2;
			
			scale.y *= Conductor.stepCrochet * .0105;
			if (PlayState.isPixelStage) {
				offsetX += 30 * EK.scalesPixel[PlayState.mania];
				if (!isSustainEnds) scale.y *= 1.05 * (6 / height); //Auto adjust note size
			} else sustainScale = SUSTAIN_SIZE / frameHeight;
			updateHitbox();
		} else {
			alpha = multAlpha = sustainScale = 1;
			if (!PlayState.isPixelStage)  {
				offsetX = 0; // Juuuust in case we recycle a sustain note to a regular note
				scale.set(ekScale, ekScale);
			} else scale.set(PlayState.daPixelZoom * ekScalePixel, PlayState.daPixelZoom * ekScalePixel);
			width = originalWidth;
			height = originalHeight;
			centerOffsets(true);
			centerOrigin();
		}
		if (isSustainNote && sustainScale != 1 && !isSustainEnds) resizeByRatio(sustainScale);
		clipRect = null;
		x += offsetX;
		return this;
	}
}