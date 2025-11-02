package objects;

import haxe.ds.Vector;

import flixel.math.FlxRect;
import flixel.graphics.FlxGraphic;

import shaders.RGBPalette;
import shaders.RGBPalette.RGBShaderReference;

import backend.NoteLoader;

@:structInit
class EventNote {
	public var strumTime:Float = 0.0;
	public var event:String = '';
	public var value1:String = '';
	public var value2:String = '';

	public function toString():String {
		return 'Name: $event | Time: $strumTime | Arguments: [$value1, $value2]}';
	}
}

typedef NoteSplashData = {
	disabled:Bool,
	texture:String,
	useGlobalShader:Bool, // breaks r/g/b/a but makes it copy default colors for your custom note
	useRGBShader:Bool,
	antialiasing:Bool,
	r:FlxColor,
	g:FlxColor,
	b:FlxColor,
	a:Float
}

/**
 * The note object used as a data structure to spawn and manage notes during gameplay.
 * 
 * If you want to make a custom note type, you should search for: "function set_noteType"
 */
class Note extends FlxSprite {
	// This is needed for the hardcoded note types to appear on the Chart Editor,
	// It's also used for backwards compatibility with 0.1 - 0.3.2 charts.
	public static final DEFAULT_NOTE_TYPES:Array<String> = [
		'', // Always leave this one empty pls
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

	public var wasGoodHit:Bool = false;
	public var missed:Bool = false;

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

	public static final SUSTAIN_SIZE:Int = 44;
	public static var swagWidth:Float = 160 * .7;
	public static var originalWidth:Float = swagWidth;
	public static var originalHeight:Float = swagWidth;
	public static var defaultNoteSkin(default, never):String = 'noteSkins/NOTE_assets';

	public static var chartArrowSkin:String = null;
	public static var pixelWidth:Vector<Int> = new Vector<Int>(2, 0);
	public static var pixelHeight:Vector<Int> = new Vector<Int>(2, 0);

	public var noteSplashData:NoteSplashData = {
		disabled: false,
		texture: null,
		antialiasing: !PlayState.isPixelStage,
		useGlobalShader: false,
		useRGBShader: PlayState.SONG != null && !PlayState.SONG.disableNoteRGB && Settings.data.noteShaders,
		r: -1,
		g: -1,
		b: -1,
		a: Settings.data.splashAlpha
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
	public var ratingMod:Float = 0; // 9 = unknown, 0.25 = shit, 0.5 = bad, 0.75 = good, 1 = sick
	public var ratingDisabled:Bool = false;

	public var texture(default, set):String = null;
	var initSkin:String = defaultNoteSkin + getNoteSkinPostfix();
	public var prevDownScr:Bool = false;

	public var noAnimation:Bool = false;
	public var noMissAnimation:Bool = false;
	public var hitCausesMiss:Bool = false;
	public var distance:Float = 2000;

	public var hitsoundDisabled:Bool = false;
	public var hitsoundChartEditor:Bool = true;

	/**
	 * Forces the hitsound to be played even if the user's hitsound volume is set to 0
	 */
	public var hitsoundForce:Bool = false;
	public var hitsoundVolume(get, default):Float = 1.0;
	function get_hitsoundVolume():Float {
		if (Settings.data.hitsoundVolume > 0)
			return Settings.data.hitsoundVolume;
		return hitsoundForce ? hitsoundVolume : 0.0;
	}
	public var hitsound:String = 'hitsounds/' + Std.string(Settings.data.hitsoundTypes).toLowerCase();

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

	static var noteFramesCollection:flixel.graphics.frames.FlxFramesCollection;
	static var noteFramesAnimation:flixel.animation.FlxAnimationController;
	function set_texture(value:String):String {
		if (value == null || value.length == 0) value = defaultNoteSkin + getNoteSkinPostfix();
		if (texture != value) {
			if (!NoteLoader.noteSkinFramesMap.exists(value)) inline NoteLoader.initNote(value);

			noteFramesCollection = NoteLoader.noteSkinFramesMap.get(value);
			noteFramesAnimation = NoteLoader.noteSkinAnimsMap.get(value);
			if (frames != noteFramesCollection) frames = noteFramesCollection;
			if (animation != noteFramesAnimation) animation.copyFrom(noteFramesAnimation);

			antialiasing = Settings.data.antialiasing;
			if (originalWidth != width || originalHeight != height) {
				setGraphicSize(Std.int(width * EK.scales[PlayState.mania]));
				updateHitbox();
				originalWidth = width;
				originalHeight = height;
			}
		} else return value;
		texture = value;
		return value;
	}

	public function defaultRGB() {
		var noteIndex:Int = EK.gfxIndex[PlayState.mania][noteData];
		var arr:Array<FlxColor> = (!PlayState.isPixelStage ? Settings.data.arrowRGBExtra : Settings.data.arrowRGBPixelExtra)[noteIndex];

		if (arr != null && noteData > -1) rgbShader.setRGB(arr[0], arr[1], arr[2]);
		else rgbShader.setRGB(FlxColor.RED, FlxColor.LIME, FlxColor.BLUE);
	}

	function set_noteType(value:String):String {
		noteSplashData.texture = PlayState.SONG != null ? PlayState.SONG.splashSkin : 'noteSplashes/noteSplashes';
		if (rgbShader != null && rgbShader.enabled) defaultRGB();

		if (noteData > -1 && noteType != value) {
			switch (value) {
				case 'Hurt Note':
					ignoreNote = mustPress;

					// splash data and colors
					if (rgbShader != null && rgbShader.enabled)
						rgbShader.setRGB(0xFF101010, FlxColor.RED, 0xFF990022);
					else {
						try {
							reloadNote('HURTNOTE_assets');
						} catch (_:Dynamic) alpha = 0.5;
					}

					// splash data and colors
					noteSplashData.r = 0xFFFF0000;
					noteSplashData.g = 0xFF101010;
					noteSplashData.texture = 'noteSplashes/noteSplashes-electric';

					// gameplay data
					missHealth = isSustainNote ? .25 : .1;
					hitCausesMiss = true;
					hitsound = 'cancelMenu';
					hitsoundChartEditor = false;
				case 'Alt Animation': animSuffix = '-alt';
				case 'No Animation': noAnimation = noMissAnimation = true;
				case 'GF Sing': gfNote = true;
			}

			if (value != null && value.length > 1) backend.NoteTypesConfig.applyNoteTypeData(this, value);
			if (hitsound != 'hitsound' && hitsoundVolume > 0) Paths.sound(hitsound); // precache new sound for being idiot-proof
			noteType = value;
		}
		return value;
	}

	public var inHitRange(get, never):Bool;
	function get_inHitRange():Bool {
		final early:Bool = strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult);
		final late:Bool = strumTime > Conductor.songPosition - (Conductor.safeZoneOffset * lateHitMult);
		return early && late;
	}

	public var hitTime(get, never):Float;
	function get_hitTime():Float return strumTime - Conductor.songPosition;

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?inEditor:Bool = false, ?createdFrom:Dynamic = null) {
		super();

		animation = new backend.animation.PsychAnimationController(this);
		antialiasing = Settings.data.antialiasing;

		if (createdFrom == null) createdFrom = PlayState.instance;
		prevNote ??= this;
		this.prevNote = prevNote;
		isSustainNote = sustainNote;
		this.inEditor = inEditor;
		this.moves = false;

		y -= 2000;

		this.strumTime = strumTime;
		if (!inEditor) this.strumTime += Settings.data.noteOffset;
		this.noteData = noteData;

		try {
			rgbShader = new RGBShaderReference(this, initializeGlobalRGBShader(noteData));
			if (PlayState.SONG != null && PlayState.SONG.disableNoteRGB || !Settings.data.noteShaders) rgbShader.enabled = false;
		} catch (e:Dynamic) rgbShader = null;
		var noteGFX:String = EK.colArray[EK.gfxIndex[PlayState.mania][noteData]];

		if (PlayState.mania != 0) x += EK.swidths[PlayState.mania] * (noteData % EK.keys(PlayState.mania));
		var scrollAnim:String = noteGFX + 'Scroll';
		if (!isSustainNote && animation.exists(scrollAnim)) animation.play(scrollAnim);
		if (PlayState.isPixelStage) offsetX = -5;

		if (prevNote != null) prevNote.nextNote = this;
		if (isSustainNote && prevNote != null) {
			alpha = multAlpha = .6;
			hitsoundDisabled = true;
			if (Settings.data.downScroll) flipY = true;

			offsetX += width * .5;
			copyAngle = false;
			var holdEndAnim:String = noteGFX + 'holdend';
			if (animation.exists(holdEndAnim)) animation.play(holdEndAnim);
			updateHitbox();
			offsetX -= width * .5;

			if (PlayState.isPixelStage) offsetX += calcPixelScale();
			if (prevNote.isSustainNote) {
				var holdAnim:String = noteGFX + 'hold';
				if (prevNote.animation.exists(holdAnim)) prevNote.animation.play(holdAnim);
				prevNote.scale.y *= Conductor.stepCrochet * .0105;
				if (createdFrom != null && createdFrom.songSpeed != null) prevNote.scale.y *= createdFrom.songSpeed;

				if (PlayState.isPixelStage) prevNote.scale.y *= 1.05 * (6 / height);
				prevNote.updateHitbox();
			}
			if (PlayState.isPixelStage) {
				scale.y *= PlayState.daPixelZoom;
				updateHitbox();
			}
			earlyHitMult = 0;
		} else if (!isSustainNote) {
			centerOffsets(true);
			centerOrigin();
		}
		x += offsetX;
	}

	public static function initializeGlobalRGBShader(noteData:Int):RGBPalette {
		var dataNum:Int = EK.gfxIndex[PlayState.mania][noteData];
		if (globalRgbShaders[dataNum] == null) {
			var newRGB:RGBPalette = new RGBPalette();
			globalRgbShaders[dataNum] = newRGB;

			var arr:Array<FlxColor> = (!PlayState.isPixelStage ? Settings.data.arrowRGBExtra : Settings.data.arrowRGBPixelExtra)[dataNum];
			if (arr != null && noteData > -1) {
				newRGB.r = arr[0];
				newRGB.g = arr[1];
				newRGB.b = arr[2];
			} else {
				newRGB.r = FlxColor.RED;
				newRGB.g = FlxColor.LIME;
				newRGB.b = FlxColor.BLUE;
			}
		}
		return globalRgbShaders[dataNum];
	}

	static var _lastValidChecked:String; // optimization
	public var correctionOffset:Float = 0; // dont mess with this
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

		var path:String = PlayState.isPixelStage ? 'pixelUI/' : '';
		var skinPixel:String = path + skin;
		var lastScaleY:Float = scale.y;
		var skinPostfix:String = getNoteSkinPostfix();
		var customSkin:String = skin + skinPostfix;

		if (customSkin == _lastValidChecked || Paths.fileExists('images/' + path + customSkin + '.png', IMAGE)) {
			skin = customSkin;
			_lastValidChecked = customSkin;
		} else skinPostfix = '';

		if (PlayState.isPixelStage) {
			var pixelEK:Int = EK.keys(EK.maxMania);
			var pixelGraphic:FlxGraphic = Paths.image(skinPixel + (isSustainNote ? 'ENDS' : '') + skinPostfix);
			loadGraphic(pixelGraphic, true, Math.floor(pixelGraphic.width / pixelEK), Math.floor(pixelGraphic.height / (isSustainNote ? 2 : 5)));

			setGraphicSize(Std.int(width * PlayState.daPixelZoom * EK.scalesPixel[PlayState.mania]));
			loadPixelNoteAnims();
			antialiasing = false;

			pixelWidth[isSustainNote ? 1 : 0] = frameWidth;
			pixelHeight[isSustainNote ? 1 : 0] = frameHeight;
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
		if (Settings.data.noteSkin != Settings.default_data.noteSkin)
			skin = '-' + Settings.data.noteSkin.trim().toLowerCase().replace(' ', '_');
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
		if (PlayState.inPlayState && PlayState.instance.cpuControlled) return;
		super.update(elapsed);

		if (mustPress) {
			canBeHit = inHitRange;
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
		if (isSustainNote) {
			flipY = Settings.data.downScroll;

			if (prevDownScr != flipY) {
				correctionOffset = isSustainNote && !flipY ? originalHeight * .5 : 0;
				prevDownScr = flipY;
			}

			scale.y = (animation != null && animation.curAnim != null && animation.curAnim.name.endsWith('end') ? .7 : Conductor.stepCrochet * .0105 * (songSpeed * multSpeed) * sustainScale);
			if (PlayState.isPixelStage) {
				scale.x = PlayState.daPixelZoom * EK.scalesPixel[PlayState.mania];
				scale.y *= PlayState.daPixelZoom * 1.19;
			}
			updateHitbox();
		}

		distance = (.45 * (Conductor.songPosition - strumTime) * songSpeed * multSpeed);
		if (!strum.downScroll) distance *= -1;

		if (copyAngle) angle = strum.direction - 90 + strum.angle + offsetAngle;
		if (copyAlpha) alpha = strum.alpha * multAlpha;

		if (copyX) @:privateAccess {
			x = strum.x + offsetX + strum._dirCos * distance;
			if (isSustainNote) x += height * strum._dirCos * .5;
		}
		if (copyY) {
			@:privateAccess y = strum.y + offsetY + correctionOffset + strum._dirSin * distance;
			if (strum.downScroll && isSustainNote) {
				if (PlayState.isPixelStage) y -= PlayState.daPixelZoom * EK.scalesPixel[PlayState.mania] * 9.5;
				y -= (frameHeight * scale.y) - (EK.swidths[PlayState.mania] * .5);
			}
		}
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

	function calcPixelScale():Float {
		var pxNoteSize:Float = switch (Settings.data.noteSkin) {
			case "Default": 35;
			case "Future": 5;
			case "Chip": 17.25;
			default: 0;
		};
		pxNoteSize *= EK.scalesPixel[PlayState.mania];
		return pxNoteSize;
	}

	override function kill() {
		active = visible = false;
		super.kill();
	}

	public function updateSkin():Void {
		if (!PlayState.isPixelStage) {
			if (!Util.notBlank(chartArrowSkin)) texture = chartArrowSkin = initSkin;
			else if (chartArrowSkin != texture) texture = chartArrowSkin;
		} else reloadNote(texture);

		var noteGFX:String = EK.colArray[EK.gfxIndex[PlayState.mania][noteData]];
		if (PlayState.isPixelStage || !isSustainNote) {
			animation.play(noteGFX + 'Scroll', true);
			offsetX = 0;
		}

		if (isSustainNote) {
			if (isSustainNote && prevNote != null) {
				flipY = Settings.data.downScroll;
				alpha = multAlpha = .6;

				if (PlayState.isPixelStage) {
					offsetX += pixelWidth[0] * .5 * PlayState.daPixelZoom;
					animation.play(noteGFX + (isSustainEnds ? 'holdend' : 'hold')); // isHoldEnd
					offsetX -= pixelWidth[1] * .5 * PlayState.daPixelZoom;
					if (!isSustainEnds) sustainScale = (PlayState.daPixelZoom / pixelHeight[1]); // Auto adjust note size
				} else {
					offsetX += width * .5;
					animation.play(noteGFX + (isSustainEnds ? 'holdend' : 'hold')); // isHoldEnd
					updateHitbox();
					offsetX -= width * .5;

					if (!isSustainEnds) sustainScale = SUSTAIN_SIZE / frameHeight;
				}
			} else {
				alpha = multAlpha = sustainScale = 1;

				if (!PlayState.isPixelStage) {
					offsetX = 0;
					scale.set(EK.scales[PlayState.mania], EK.scales[PlayState.mania]);
					width = originalWidth;
					height = originalHeight;
				} else scale.set(PlayState.daPixelZoom * EK.scalesPixel[PlayState.mania], PlayState.daPixelZoom * EK.scalesPixel[PlayState.mania]);
			}
		}
		correctionOffset = isSustainNote && !flipY ? originalHeight * .5 : 0;

		if (sustainScale != 1 && !isSustainEnds)
			resizeByRatio(sustainScale);
		clipRect = null;
		x += offsetX;
	}
}