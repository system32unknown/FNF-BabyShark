package objects;

import flixel.math.FlxRect;
import backend.NoteTypesConfig;

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
	r:FlxColor,
	g:FlxColor,
	b:FlxColor,
	a:Float
}

class Note extends FlxSprite {
	public static var keysShit:Map<Int, Map<String, Dynamic>> = data.EkData.keysShit;
	
	public var extraData:Map<String, Dynamic> = new Map<String, Dynamic>();
	public var strumTime:Float = 0;

	public var mustPress:Bool = false;
	public var noteData:Int = 0;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var hasMissed:Bool = false;
	public var wasGoodHit:Bool = false;
	public var ignoreNote:Bool = false;
	public var hitByOpponent:Bool = false;
	public var prevNote:Note;

	public var tail:Array<Note> = []; // for sustains
	public var parent:Note;
	public var blockHit:Bool = false; // only works for player

	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;
	public var noteType(default, set):String = null;
	public var isHideableNote:Bool = false;

	public var eventName:String = '';
	public var eventLength:Int = 0;
	public var eventVal1:String = '';
	public var eventVal2:String = '';

	public var rgbShader:RGBShaderReference;
	public static var globalRgbShaders:Array<RGBPalette> = [];
	public var inEditor:Bool = false;

	public var animSuffix:String = '';
	public var gfNote:Bool = false;
	public var earlyHitMult:Float = 1;
	public var lateHitMult:Float = 1;

	public static var SUSTAIN_SIZE:Int = 44;
	public static var swagWidth:Float = 160 * .7;
	public static var defaultNoteSkin:String = 'noteSkins/NOTE_assets';

	// Lua shit
	public var noteSplashDisabled:Bool = false;
	public var noteSplashTexture:String = null;
	public var noteSplashHSB:Array<Float> = [0, 0, 0];

	public var noteSplashData:NoteSplashData = {
		disabled: false,
		texture: null,
		antialiasing: !PlayState.isPixelStage,
		useGlobalShader: false,
		useRGBShader: (PlayState.SONG != null) ? !(PlayState.SONG.disableNoteRGB) : true,
		r: -1,
		g: -1,
		b: -1,
		a: ClientPrefs.getPref('splashOpacity')
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

	public var hitHealth:Float = .023;
	public var missHealth:Float = .0475;
	public var rating:String = 'unknown';
	public var ratingMod:Float = 0; //9 = unknown, 0.25 = shit, 0.5 = bad, 0.75 = good, 1 = sick
	public var ratingDisabled:Bool = false;

	public var texture(default, set):String = null;

	public var noAnimation:Bool = false;
	public var noMissAnimation:Bool = false;
	public var hitCausesMiss:Bool = false;
	public var distance:Float = 2000; //plan on doing scroll directions soon -bb

	public var hitsoundDisabled:Bool = false;
	public var hitsoundChartEditor:Bool = true;
	public var hitsound:String = 'hitsounds/' + Std.string(ClientPrefs.getPref('hitsoundTypes')).toLowerCase();

	function set_multSpeed(value:Float):Float {
		resizeByRatio(value / multSpeed);
		return multSpeed = value;
	}

	public function resizeByRatio(ratio:Float) { //haha funny twitter shit
		if(isSustainNote && animation.curAnim != null && !animation.curAnim.name.endsWith('tail')) {
			scale.y *= ratio;
			updateHitbox();
		}
	}

	function set_texture(value:String):String {
		if(texture != value) reloadNote(value);
		return texture = value;
	}

	public function defaultRGB() {
		var arr:Array<FlxColor> = ClientPrefs.getPref('arrowRGBExtra')[EK.gfxIndex[PlayState.mania][noteData]];
		if(PlayState.isPixelStage) arr = ClientPrefs.getPref('arrowRGBPixelExtra')[EK.gfxIndex[PlayState.mania][noteData]];

		if (noteData > -1 && noteData <= PlayState.mania) {
			rgbShader.r = arr[0];
			rgbShader.g = arr[1];
			rgbShader.b = arr[2];
		}
	}

	function set_noteType(value:String):String {
		noteSplashTexture = PlayState.SONG != null ? PlayState.SONG.splashSkin : 'noteSplashes';
		defaultRGB();

		if(noteData > -1 && noteType != value) {
			switch(value) {
				case 'Hurt Note':
					ignoreNote = true;

					rgbShader.r = 0xFF101010;
					rgbShader.g = 0xFFFF0000;
					rgbShader.b = 0xFF990022;

					// splash data and colors
					noteSplashData.r = 0xFFFF0000;
					noteSplashData.g = 0xFF101010;
					noteSplashData.texture = 'noteSplashes/noteSplashes-electric';

					missHealth = isSustainNote ? .25 : .1;
					hitCausesMiss = true;
					isHideableNote = true;
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
			if (value != null && value.length > 1) NoteTypesConfig.applyNoteTypeData(this, value);
			if (hitsound != 'hitsound' && ClientPrefs.getPref('hitsoundVolume') > 0) Paths.sound(hitsound); //precache new sound for being idiot-proof
			noteType = value;
		}
		return value;
	}

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?inEditor:Bool = false, ?createdFrom:Dynamic = null) {
		super();

		animation = new backend.animation.PsychAnimationController(this);

		antialiasing = ClientPrefs.getPref('Antialiasing');
		if(createdFrom == null) createdFrom = PlayState.instance;

		if (prevNote == null) prevNote = this;

		this.prevNote = prevNote;
		isSustainNote = sustainNote;
		this.inEditor = inEditor;
		this.moves = false;

		x += (ClientPrefs.getPref('middleScroll') ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X) + 50 - EK.posRest[PlayState.mania];
		y -= 2000;
		this.strumTime = strumTime;
		if(!inEditor) this.strumTime += ClientPrefs.getPref('noteOffset');

		this.noteData = noteData;

		if(noteData > -1) {
			texture = '';
			rgbShader = new RGBShaderReference(this, initializeGlobalRGBShader(noteData));
			if(PlayState.SONG != null && PlayState.SONG.disableNoteRGB) rgbShader.enabled = false;

			if (PlayState.mania != 0) x += EK.swidths[PlayState.mania] * (noteData % (PlayState.mania + 1));
			if(!isSustainNote && noteData < PlayState.mania + 1)
				animation.play(EK.colArray[EK.gfxIndex[PlayState.mania][noteData]] + 'Scroll');
		}

		if (isSustainNote && prevNote != null) {
			alpha = .6;
			multAlpha = .6;
			hitsoundDisabled = true;
			if(ClientPrefs.getPref('downScroll')) flipY = true;

			offsetX += width / 2;
			copyAngle = false;

			animation.play(EK.colArray[EK.gfxIndex[PlayState.mania][noteData]] + 'holdend');
			updateHitbox();

			offsetX -= width / 2;

			if (PlayState.isPixelStage) offsetX += 30;

			if (prevNote.isSustainNote) {
				prevNote.animation.play(keysShit.get(PlayState.mania).get('letters')[prevNote.noteData] + ' hold');

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

	var _lastNoteOffX:Float = 0;
	public var originalHeight:Float = 6;
	public var correctionOffset:Float = 0;
	function reloadNote(texture:String = '', postfix:String = '') {
		if(texture == null) texture = '';
		if(postfix == null) postfix = '';

		var skin:String = texture + postfix;
		if (texture.length < 1) {
			skin = PlayState.SONG != null ? PlayState.SONG.arrowSkin : null;
			if(skin == null || skin.length < 1)
				skin = defaultNoteSkin + postfix;
		}

		var animName:String = null;
		if(animation.curAnim != null)
			animName = animation.curAnim.name;

		var skinPixel:String = skin;
		var lastScaleY:Float = scale.y;
		if(PlayState.isPixelStage) {
			if(isSustainNote) {
				var graphic = Paths.image('pixelUI/' + skinPixel + 'ENDS');
				loadGraphic(graphic, true, Math.floor(graphic.width / EK.pixelNotesDivisionValue), Math.floor(graphic.height / 2));
				originalHeight = graphic.height / 2;
			} else {
				var graphic = Paths.image('pixelUI/' + skinPixel);
				loadGraphic(graphic, true, Math.floor(graphic.width / EK.pixelNotesDivisionValue), Math.floor(graphic.height / 5));
			}
			setGraphicSize(Std.int(width * PlayState.daPixelZoom));
			loadPixelNoteAnims();
			antialiasing = false;

			if(isSustainNote) {
				offsetX += _lastNoteOffX;
				_lastNoteOffX = (width - 7) * (PlayState.daPixelZoom / 2);
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

	function loadNoteAnims() {
		var defaultWidth = 157;
		var defaultHeight = 154;

		for (letter in EK.gfxLetter) {
			if (isSustainNote) {
				animation.addByPrefix('$letter hold', '$letter hold', 24);
				animation.addByPrefix('$letter tail', '$letter tail', 24);
			} else animation.addByPrefix(letter, '${letter}0', 24);
		}

		if (!isSustainNote)
			setGraphicSize(Std.int(defaultWidth * EK.scales[PlayState.mania]));
		else setGraphicSize(Std.int(defaultWidth * EK.scales[PlayState.mania]), Std.int(defaultHeight));
		updateHitbox();
	}

	function loadPixelNoteAnims() {
		if(isSustainNote) {
			for (i => letter in EK.gfxLetter) {
				animation.add('$letter hold', [i], 24);
				animation.add('$letter tail', [i + EK.pixelNotesDivisionValue], 24);
			}
		} else for (i => letter in EK.gfxLetter) animation.add(letter, [i + EK.pixelNotesDivisionValue], 24);
	}

	inline public function checkDiff(songPos:Float):Bool {
		return (strumTime > songPos - (Conductor.safeZoneOffset * lateHitMult) && strumTime < songPos + (Conductor.safeZoneOffset * earlyHitMult));
	}
	inline public function checkHit(songPos:Float):Bool {
		return (strumTime <= songPos + (Conductor.safeZoneOffset * earlyHitMult) && ((isSustainNote && prevNote.wasGoodHit) || strumTime <= songPos));
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (mustPress) {
			canBeHit = checkDiff(Conductor.songPosition);
			if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit) tooLate = true;
		} else canBeHit = false;

		if (tooLate && !inEditor && alpha > .3) alpha = .3;
	}

	public function followStrumNote(myStrum:StrumNote, songSpeed:Float = 1) {
		var strumX:Float = myStrum.x;
		var strumY:Float = myStrum.y;
		var strumAngle:Float = myStrum.angle;
		var strumAlpha:Float = myStrum.alpha;
		var strumDirection:Float = myStrum.direction;

		distance = (.45 * (Conductor.songPosition - strumTime) * songSpeed * multSpeed);
		if(!myStrum.downScroll) distance *= -1;

		var angleDir = strumDirection * Math.PI / 180;
		if(copyAngle) angle = strumDirection - 90 + strumAngle + offsetAngle;

		if(copyAlpha) alpha = strumAlpha * multAlpha;
		if(copyX) x = strumX + offsetX + Math.cos(angleDir) * distance;
		if(copyY) {
			y = strumY + offsetY + correctionOffset + Math.sin(angleDir) * distance;
			if(myStrum.downScroll && isSustainNote) {
				if(PlayState.isPixelStage) y -= PlayState.daPixelZoom * 9.5;
				y -= (frameHeight * scale.y) - (swagWidth / 2);
			}
		}
	}

	public function clipToStrumNote(myStrum:StrumNote) {
		final center:Float = myStrum.y + offsetY + swagWidth / 2;
		if(isSustainNote && (mustPress || !ignoreNote) && (!mustPress || (wasGoodHit || (prevNote.wasGoodHit && !canBeHit)))) {
			final swagRect:FlxRect = (clipRect == null ? FlxRect.get(0, 0, frameWidth, frameHeight) : clipRect);
	
			if (myStrum.downScroll) {
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

	override function destroy() {
		clipRect = flixel.util.FlxDestroyUtil.put(clipRect);
		super.destroy();
	}

	@:noCompletion override function set_clipRect(rect:FlxRect):FlxRect {
		clipRect = rect;
		if (frames != null) frame = frames.frames[animation.frameIndex];
		return rect;
	}
}