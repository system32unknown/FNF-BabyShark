package game;

import flixel.FlxSprite;
import editors.ChartingState;
import shaders.ColorSwap;
import utils.ClientPrefs;
import states.PlayState;
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
	public static var noteSplashOffsets:Map<Int, Array<Int>> = [
		0 => [20, 10],
		9 => [10, 20]
	];
	public static var noteSplashScales:Array<Float> = EKData.splashScales;

	public var extraData:Map<String, Dynamic> = [];

	public static var ammo:Array<Int> = EKData.gun;
	public static var minMania:Int = 0;
	public static var maxMania:Int = 17;
	public static var xmlMax:Int = 17; // This specifies the max of the splashes can go

	public static var maxManiaUI_integer:Int = maxMania + 1;
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
	public var wasGoodHit:Bool = false;
	public var ignoreNote:Bool = false;
	public var hitByOpponent:Bool = false;
	public var prevNote:Note;

	public var randomized:Bool = false;
	public var localScrollSpeed:Float = 1;

	public var spawned:Bool = false;

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
	public var earlyHitMult:Float = 0.5;
	public var lateHitMult:Float = 1;
	public var lowPriority:Bool = false;

	public static var swagWidth:Float = 160 * 0.7;

	// Lua shit
	public var noteSplashDisabled:Bool = false;
	public var noteSplashTexture:String = null;
	public var noteSplashHue:Float = 0;
	public var noteSplashSat:Float = 0;
	public var noteSplashBrt:Float = 0;

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
	public var changeAnim:Bool = true;
	public var changeColSwap:Bool = true;
	
	var defaultWidth:Float = 157;
	var defaultHeight:Float = 154;

	public function resizeByRatio(ratio:Float) { //haha funny twitter shit
		if(isSustainNote && !animation.curAnim.name.endsWith('tail')) {
			scale.y *= ratio;
			updateHitbox();
		}
	}

	private function set_multSpeed(value:Float):Float {
		resizeByRatio(value / multSpeed);
		multSpeed = value;
		return value;
	}

	private function set_texture(value:String):String {
		if(texture != value)
			reloadNote('', value);
		texture = value;
		return value;
	}

	private function set_noteType(value:String):String {
		var luaPrefix:String = '';
		noteSplashTexture = PlayState.SONG.splashSkin;
		var arrowHSV:Array<Array<Int>> = ClientPrefs.getPref('arrowHSV');
		var arrowIndex:Int = Std.int(Note.keysShit.get(mania).get('pixelAnimIndex')[noteData] % Note.ammo[mania]);
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
					colorSwap.hue = 0;
					colorSwap.saturation = 0;
					colorSwap.brightness = 0;
					lowPriority = true;

					if(isSustainNote)
						missHealth = 0.1;
					else missHealth = 0.3;
					hitCausesMiss = true;
				case 'Danger Note':
					reloadNote('DANGER', 'NOTE_assets');
					noteSplashTexture = 'DANGERnoteSplashes';
					colorSwap.hue = 0;
					colorSwap.saturation = 0;
					colorSwap.brightness = 0;
					noMissAnimation = true;
					if (isSustainNote) 
						missHealth = 0.3;
					else missHealth = 0.5;
					hitCausesMiss = false;
				case 'Kill Note':
					ignoreNote = true;
					reloadNote('KILL', 'NOTE_assets');
					noteSplashTexture = 'HURTnoteSplashes';
					colorSwap.hue = 0;
					colorSwap.saturation = 0;
					colorSwap.brightness = 0;
					missHealth = 2;
					hitCausesMiss = true;
				case 'Alt Animation':
					animSuffix = '-alt';
				case 'No Animation':
					noAnimation = true;
					noMissAnimation = true;
				case 'GF Sing':
					gfNote = true;
				case '' | 'Hey!':
				default:
					#if MODS_ALLOWED
					if (Paths.image(luaPrefix + 'NOTE_assets') != null)
						reloadNote(luaPrefix, 'NOTE_assets');
					else trace('Suggestion: rename $value texture to ${luaPrefix}NOTE_assets');
					#end
			}
			noteType = value;
		}
		noteSplashHue = colorSwap.hue;
		noteSplashSat = colorSwap.saturation;
		noteSplashBrt = colorSwap.brightness;
		return value;
	}

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?inEditor:Bool = false)
	{
		super();

		mania = PlayState.mania;

		if (prevNote == null)
			prevNote = this;

		this.prevNote = prevNote;
		isSustainNote = sustainNote;
		this.inEditor = inEditor;

		x += (ClientPrefs.getPref('middleScroll') ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X) + 50;
		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y -= 2000;
		this.strumTime = strumTime;
		if(!inEditor) this.strumTime += ClientPrefs.getPref('noteOffset');

		this.noteData = noteData;

		if(noteData > -1) {
			texture = '';
			colorSwap = new ColorSwap();
			shader = colorSwap.shader;

			x += swagWidth * (noteData % Note.ammo[mania]);
			if(!isSustainNote && noteData > -1 && noteData < Note.maxManiaUI_integer) { //Doing this 'if' check to fix the warnings on Senpai songs
				animation.play(Note.keysShit.get(mania).get('letters')[noteData]);
			}
		}

		if (isSustainNote && prevNote != null)
		{
			alpha = 0.6;
			multAlpha = 0.6;
			hitsoundDisabled = true;
			if(ClientPrefs.getPref('downScroll')) flipY = true;

			offsetX += width / 2;
			copyAngle = false;

			animation.play(Note.keysShit.get(mania).get('letters')[noteData] + ' tail');

			updateHitbox();

			offsetX -= width / 2;

			if (PlayState.isPixelStage)
				offsetX += 30 * Note.pixelScales[mania];

			if (prevNote.isSustainNote) {
				prevNote.animation.play(Note.keysShit.get(mania).get('letters')[prevNote.noteData] + ' hold');

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
		} else if(!isSustainNote) {
			earlyHitMult = 1;
		}
		x += offsetX;
	}

	var lastNoteOffsetX_Pixel:Float = 0;
	public var originalHeightForCalcs:Float = 6;
	function reloadNote(?prefix:String = '', ?texture:String = '', ?suffix:String = '') {
		if (prefix == null) prefix = '';
		if (texture == null) texture = '';
		if (suffix == null) suffix = '';

		var skin:String = texture;
		if (texture.length < 1) {
			skin = PlayState.SONG.arrowSkin;
			if(skin == null || skin.length < 1) {
				skin = 'NOTE_assets';
			}
		}

		var animName:String = null;
		if(animation.curAnim != null) {
			animName = animation.curAnim.name;
		}

		var arraySkin:Array<String> = skin.split('/');
		arraySkin[arraySkin.length - 1] = prefix + arraySkin[arraySkin.length - 1] + suffix;

		var lastScaleY:Float = scale.y;
		var blahblah:String = arraySkin.join('/');

		if(PlayState.isPixelStage) {
			if(isSustainNote) {
				loadGraphic(Paths.image('pixelUI/' + blahblah + 'ENDS'));
				width /= pixelNotesDivisionValue;
				height /= 2;
				originalHeightForCalcs = height;
				loadGraphic(Paths.image('pixelUI/' + blahblah + 'ENDS'), true, Math.floor(width), Math.floor(height));
			} else {
				loadGraphic(Paths.image('pixelUI/' + blahblah));
				width /= pixelNotesDivisionValue;
				height /= 5;
				loadGraphic(Paths.image('pixelUI/' + blahblah), true, Math.floor(width), Math.floor(height));
			}
			defaultWidth = width;
			setGraphicSize(Std.int(width * PlayState.daPixelZoom * Note.pixelScales[mania]));
			loadPixelNoteAnims();
			antialiasing = false;

			if(isSustainNote) {
				offsetX += lastNoteOffsetX_Pixel;
				lastNoteOffsetX_Pixel = (width - 7) * (PlayState.daPixelZoom / 2);
				offsetX -= lastNoteOffsetX_Pixel;
			}
		} else {
			frames = Paths.getSparrowAtlas(blahblah);
			loadNoteAnims();
			antialiasing = ClientPrefs.getPref('globalAntialiasing');
		}
		if(isSustainNote) scale.y = lastScaleY;
		updateHitbox();

		if(animName != null)
			animation.play(animName, true);

		if(inEditor) {
			setGraphicSize(ChartingState.GRID_SIZE, ChartingState.GRID_SIZE);
			updateHitbox();
		}
	}

	function loadNoteAnims() {
		for (i in 0...gfxLetter.length) {
			animation.addByPrefix(gfxLetter[i], gfxLetter[i] + '0');

			if (isSustainNote) {
				animation.addByPrefix(gfxLetter[i] + ' hold', gfxLetter[i] + ' hold');
				animation.addByPrefix(gfxLetter[i] + ' tail', gfxLetter[i] + ' tail');
			}

			if (!isSustainNote)
				setGraphicSize(Std.int(defaultWidth * scales[mania]));
			else setGraphicSize(Std.int(defaultWidth * scales[mania]), Std.int(defaultHeight * scales[0]));

			updateHitbox();
		}
	}

	function loadPixelNoteAnims() {
		if(isSustainNote) {
			for (i in 0...gfxLetter.length) {
				animation.add(gfxLetter[i] + ' hold', [i]);
				animation.add(gfxLetter[i] + ' tail', [i + pixelNotesDivisionValue]);
			}
		} else {
			for (i in 0...gfxLetter.length) {
				animation.add(gfxLetter[i], [i + pixelNotesDivisionValue]);
			}
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		mania = PlayState.mania;

		if (mustPress) {
			// ok river
			if (strumTime > Conductor.songPosition - (Conductor.safeZoneOffset * lateHitMult)
				&& strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult))
				canBeHit = true;
			else canBeHit = false;

			if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit)
				tooLate = true;
		} else {
			canBeHit = false;

			if (strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult)) {
				if ((isSustainNote && prevNote.wasGoodHit) || strumTime <= Conductor.songPosition)
					wasGoodHit = true;
			}
		}

		if (tooLate && !inEditor) {
			if (alpha > .3) alpha = .3;
		}
	}
}