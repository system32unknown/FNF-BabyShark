package objects;

import flixel.math.FlxRect;
import shaders.ColorSwap;
import data.EkData;

typedef EventNote = {
	strumTime:Float,
	event:String,
	value1:String,
	value2:String
}

class Note extends FlxSprite
{
	public static var gfxLetter:Array<String> = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R'];
	public static var scales:Array<Float> = EKData.scales;
	public static var lessX:Array<Int> = EKData.lessX;
	public static var separator:Array<Int> = EKData.noteSep;
	public static var xtra:Array<Float> = EKData.offsetX;
	public static var posRest:Array<Float> = EKData.restPosition;
	public static var gridSizes:Array<Int> = EKData.gridSizes;
	public static var noteSplashScales:Array<Float> = EKData.splashScales;

	public var extraData:Map<String, Dynamic> = new Map<String, Dynamic>();

	public static var ammo:Array<Int> = EKData.gun;
	public static var minMania:Int = 0;
	public static var maxMania:Int = 17;
	public static var xmlMax:Int = 17; // This specifies the max of the splashes can go
	public static var defaultMania:Int = 3;

	public static var pixelNotesDivisionValue:Int = 18;
	public static var pixelScales:Array<Float> = EKData.pixelScales;

	public static var keysShit:Map<Int, Map<String, Dynamic>> = EKData.keysShit;
	public var mania:Int = 1;

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

	public var eventName:String = '';
	public var eventLength:Int = 0;
	public var eventVal1:String = '';
	public var eventVal2:String = '';

	public var colorSwap:ColorSwap;
	public var inEditor:Bool = false;

	public var animSuffix:String = '';
	public var gfNote:Bool = false;
	public var lateHitMult:Float = 1;
	public var earlyHitMult:Float = 1;

	public static var SUSTAIN_SIZE:Int = 44;
	public static var swagWidth:Float = 160 * .7;
	public static var defaultNoteSkin:String = 'noteSkins/NOTE_assets';

	// Lua shit
	public var noteSplashDisabled:Bool = false;
	public var noteSplashTexture:String = null;
	public var noteSplashHSB:Array<Float> = [0, 0, 0];

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var offsetAngle:Float = 0;
	public var multAlpha:Float = 1;
	public var multSpeed(default, set):Float = 1;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;

	public var hitHealth:Float = 0.023;
	public var missHealth:Float = 0.0475;
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
	public var hitsound:String = 'hitsound';
	public var changeAnim:Bool = true;
	public var changeColSwap:Bool = true;
	
	var defaultWidth:Float = 157;
	var defaultHeight:Float = 154;

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

	function set_noteType(value:String):String {
		noteSplashTexture = PlayState.SONG != null ? PlayState.SONG.splashSkin : 'noteSplashes';
		var arrowHSV:Array<Array<Int>> = ClientPrefs.getPref('arrowHSV');
		var arrowIndex:Int = Std.int(keysShit.get(mania).get('pixelAnimIndex')[noteData] % ammo[mania]);
		if (noteData > -1 && noteData < arrowHSV.length) {
			colorSwap.hue = arrowHSV[arrowIndex][0] / 360;
			colorSwap.saturation = arrowHSV[arrowIndex][1] / 100;
			colorSwap.brightness = arrowHSV[arrowIndex][2] / 100;
		}

		if(noteData > -1 && noteType != value) {
			switch(value) {
				case 'Hurt Note':
					ignoreNote = true;
					reloadNote('HURT', 'NOTE_assets');
					noteSplashTexture = 'HURTnoteSplashes';
					colorSwap.hue = colorSwap.saturation = colorSwap.brightness = 0;

					missHealth = (isSustainNote ? .1 : .25);
					hitCausesMiss = true;
					hitsound = 'cancelMenu';
					hitsoundChartEditor = false;
				case 'Danger Note':
					reloadNote('DANGER', 'NOTE_assets');
					noteSplashTexture = 'DANGERnoteSplashes';
					colorSwap.hue = colorSwap.saturation = colorSwap.brightness = 0;
					noMissAnimation = true;
					missHealth = (isSustainNote ? .3 : .5);
					hitCausesMiss = false;
				case 'Kill Note':
					ignoreNote = true;
					reloadNote('KILL', 'NOTE_assets');
					noteSplashTexture = 'HURTnoteSplashes';
					colorSwap.hue = colorSwap.saturation = colorSwap.brightness = 0;
					missHealth = PlayState.instance.healthMax;
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
				#if MODS_ALLOWED
				case '' | 'Hey!':
				default:
					final luaPrefix = value.split(" ")[0].toUpperCase();
					if (Paths.fileExists('images/${value.toUpperCase()}_assets.png', IMAGE)) {
						reloadNote(luaPrefix, '_assets');
						colorSwap.hue = colorSwap.saturation = colorSwap.brightness = 0;
					}
				#end
			}
			noteType = value;
		}
		noteSplashHSB = [colorSwap.hue, colorSwap.saturation, colorSwap.brightness];
		return value;
	}

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?inEditor:Bool = false) {
		super();

		mania = PlayState.mania;

		if (prevNote == null) prevNote = this;

		this.prevNote = prevNote;
		isSustainNote = sustainNote;
		this.inEditor = inEditor;
		this.moves = false;

		x += (ClientPrefs.getPref('middleScroll') ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X) + 50;
		y -= 2000;
		this.strumTime = strumTime;
		if(!inEditor) this.strumTime += ClientPrefs.getPref('noteOffset');

		this.noteData = noteData;

		if(noteData > -1) {
			texture = '';
			colorSwap = new ColorSwap();
			shader = colorSwap.shader;

			x += swagWidth * (noteData % ammo[mania]);
			if(!isSustainNote && noteData > -1)
				animation.play(keysShit.get(mania).get('letters')[noteData % ammo[mania]]);
		}

		if (isSustainNote && prevNote != null) {
			alpha = .6;
			multAlpha = .6;
			hitsoundDisabled = true;
			if(ClientPrefs.getPref('downScroll')) flipY = true;

			offsetX += width / 2;
			copyAngle = false;

			animation.play(keysShit.get(mania).get('letters')[noteData] + ' tail');
			updateHitbox();

			offsetX -= width / 2;

			if (PlayState.isPixelStage)
				offsetX += 30 * pixelScales[mania];

			if (prevNote.isSustainNote) {
				prevNote.animation.play(keysShit.get(mania).get('letters')[prevNote.noteData] + ' hold');

				prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.05;
				if(PlayState.instance != null) {
					prevNote.scale.y *= PlayState.instance.songSpeed;
				}

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
	static var _lastValidChecked:String; //optimization
	public var originalHeight:Float = 6;
	public var correctionOffset:Float = 0;
	function reloadNote(texture:String = '', postfix:String = '') {
		if(texture == null) texture = '';
		if(postfix == null) postfix = '';

		var skin:String = texture;
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
		var skinPostfix:String = getNoteSkinPostfix();
		var customSkin:String = skin + skinPostfix;
		var path:String = PlayState.isPixelStage ? 'pixelUI/' : '';
		if(customSkin == _lastValidChecked || Paths.fileExists('images/' + path + customSkin + '.png', IMAGE)) {
			skin = customSkin;
			_lastValidChecked = customSkin;
		} else skinPostfix = '';

		defaultWidth = 157;
		defaultHeight = 154;
		if(PlayState.isPixelStage) {
			if(isSustainNote) {
				var graphic = Paths.image('pixelUI/' + skinPixel + 'ENDS' + skinPostfix);
				loadGraphic(graphic, true, Math.floor(graphic.width / pixelNotesDivisionValue), Math.floor(graphic.height / 2));
				originalHeight = graphic.height / 2;
			} else {
				var graphic = Paths.image('pixelUI/' + skinPixel + skinPostfix);
				loadGraphic(graphic, true, Math.floor(graphic.width / pixelNotesDivisionValue), Math.floor(graphic.height / 5));
			}
			defaultWidth = width;
			setGraphicSize(Std.int(width * PlayState.daPixelZoom * pixelScales[mania]));
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

	public static function getNoteSkinPostfix() {
		var skin:String = '';
		if(ClientPrefs.getPref('noteSkin') != ClientPrefs.defaultprefs.get('noteSkin'))
			skin = '-' + ClientPrefs.getPref('noteSkin').trim().toLowerCase().replace(' ', '_');
		return skin;
	}

	function loadNoteAnims() {
		for (letter in gfxLetter) {
			if (isSustainNote) {
				animation.addByPrefix('$letter hold', '$letter hold', 24);
				animation.addByPrefix('$letter tail', '$letter tail', 24);
			} else animation.addByPrefix(letter, '${letter}0', 24);
		}

		setGraphicSize(Std.int(defaultWidth * scales[mania]), (isSustainNote ? Std.int(defaultHeight * scales[0]) : 0));
		updateHitbox();
	}

	function loadPixelNoteAnims() {
		if(isSustainNote) {
			for (i => letter in gfxLetter) {
				animation.add('$letter hold', [i], 24);
				animation.add('$letter tail', [i + pixelNotesDivisionValue], 24);
			}
		} else {
			for (i => letter in gfxLetter) {
				animation.add(letter, [i + pixelNotesDivisionValue], 24);
			}
		}
	}

	inline public function checkDiff(songPos:Float):Bool {
		return (strumTime > songPos - (Conductor.safeZoneOffset * lateHitMult) && strumTime < songPos + (Conductor.safeZoneOffset * earlyHitMult));
	}

	inline public function checkHit(songPos:Float):Bool {
		return strumTime <= songPos + (Conductor.safeZoneOffset * earlyHitMult) && ((isSustainNote && prevNote.wasGoodHit) || strumTime <= songPos);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (mustPress) {
			canBeHit = checkDiff(Conductor.songPosition);
			if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit)
				tooLate = true;
		} else canBeHit = false;

		if (tooLate && !inEditor)
			if (alpha > .3) alpha = .3;
	}

	public function followStrumNote(myStrum:StrumNote, songSpeed:Float = 1) {
		var strumX:Float = myStrum.x;
		var strumY:Float = myStrum.y;
		var strumAngle:Float = myStrum.angle;
		var strumAlpha:Float = myStrum.alpha;
		var strumDirection:Float = myStrum.direction;

		distance = (0.45 * (Conductor.songPosition - strumTime) * songSpeed * multSpeed);
		if (!myStrum.downScroll) distance *= -1;

		var angleDir = strumDirection * Math.PI / 180;
		if (copyAngle) angle = strumDirection - 90 + strumAngle + offsetAngle;

		if(copyAlpha) alpha = strumAlpha * multAlpha;
		if(copyX) x = strumX + offsetX + Math.cos(angleDir) * distance;
		if(copyY) {
			y = strumY + offsetY + correctionOffset + Math.sin(angleDir) * distance;
			if(myStrum.downScroll && isSustainNote) {
				if(PlayState.isPixelStage)
					y -= PlayState.daPixelZoom * 9.5;
				y -= (frameHeight * scale.y) - (Note.swagWidth / 2);
			}
		}
	}

	public function clipToStrumNote(myStrum:StrumNote) {
		var center:Float = myStrum.y + offsetY + Note.swagWidth / 2;
		if(isSustainNote && (mustPress || !ignoreNote) && (!mustPress || (wasGoodHit || (prevNote.wasGoodHit && !canBeHit)))) {
			var swagRect:FlxRect = clipRect;
			if(swagRect == null) swagRect = new FlxRect(0, 0, frameWidth, frameHeight);
	
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
		shader = null;
		colorSwap = null;
		super.destroy();
	}

	@:noCompletion
	override function set_clipRect(rect:FlxRect):FlxRect {
		clipRect = rect;

		if (frames != null)
			frame = frames.frames[animation.frameIndex];

		return rect;
	}
}