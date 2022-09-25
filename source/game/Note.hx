package game;

import flixel.FlxSprite;
import editors.ChartingState;
import shaders.ColorSwap;
import utils.ClientPrefs;
import states.PlayState;

using StringTools;

typedef EventNote = {
	strumTime:Float,
	event:String,
	value1:String,
	value2:String
}

class Note extends FlxSprite
{
	public static var gfxLetter:Array<String> = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'];
	public static var scales:Array<Float> = [0.9, 0.85, 0.8, 0.7, 0.66, 0.6, 0.55, 0.50, 0.46, 0.39, 0.36];
	public static var lessX:Array<Int> = [0, 0, 0, 0, 0, 8, 7, 8, 8, 7, 6];
	public static var separator:Array<Int> = [0, 0, 1, 1, 2, 2, 2, 3, 3, 4, 4];
	public static var xtra:Array<Int> = [150, 89, 0, 0, 0, 0, 0, 0, 0, 0, 0];
	public static var posRest:Array<Int> = [0, 0, 0, 0, 25, 32, 46, 52, 60, 40, 30];
	public static var gridSizes:Array<Int> = [40, 40, 40, 40, 40, 40, 40, 40, 40, 35, 30];
	public static var offsets:Array<Dynamic> = [[20, 10], [10, 10], [10, 10], [10, 10], [10, 10], [10, 10], [10, 10], [10, 10], [10, 10], [10, 20], [10, 10], [10, 10]];

	public static var minMania:Int = 0;
	public static var maxMania:Int = 9;

	public static var maxManiaUI_integer:Int = maxMania + 1;
	public static var defaultMania:Int = 3;

	public static var keysShit:Map<Int, Map<String, Dynamic>> = [
		0 => ["letters" => ["E"], "anims" => ["UP"], "strumAnims" => ["SPACE"], "pixelAnimIndex" => [4], "sustaincolor" => ['cccccc']],
		1 => ["letters" => ["A", "D"], "anims" => ["LEFT", "RIGHT"], "strumAnims" => ["LEFT", "RIGHT"], "pixelAnimIndex" => [0, 3], "sustaincolor" => ['c24b99', 'f9393f']],
		2 => ["letters" => ["A", "E", "D"], "anims" => ["LEFT", "UP", "RIGHT"], "strumAnims" => ["LEFT", "SPACE", "RIGHT"], "pixelAnimIndex" => [0, 4, 3], "sustaincolor" => ['c24b99', 'cccccc', 'f9393f']],
		3 => ["letters" => ["A", "B", "C", "D"], "anims" => ["LEFT", "DOWN", "UP", "RIGHT"], "strumAnims" => ["LEFT", "DOWN", "UP", "RIGHT"], "pixelAnimIndex" => [0, 1, 2, 3], "sustaincolor" => ['c24b99', '00ffff', '12fa05', 'f9393f']],
		4 => ["letters" => ["A", "B", "E", "C", "D"], "anims" => ["LEFT", "DOWN", "UP", "UP", "RIGHT"],
			 "strumAnims" => ["LEFT", "DOWN", "SPACE", "UP", "RIGHT"], "pixelAnimIndex" => [0, 1, 4, 2, 3], "sustaincolor" => ['c24b99', '00ffff', 'cccccc' ,'12fa05', 'f9393f']],
		5 => ["letters" => ["A", "C", "D", "F", "B", "I"], "anims" => ["LEFT", "UP", "RIGHT", "LEFT", "DOWN", "RIGHT"],
			 "strumAnims" => ["LEFT", "UP", "RIGHT", "LEFT", "DOWN", "RIGHT"], "pixelAnimIndex" => [0, 2, 3, 5, 1, 8], "sustaincolor" => ['c24b99', '12fa05', 'f9393f', 'ffff00', '00ffff', '0033ff']],
		6 => ["letters" => ["A", "C", "D", "E", "F", "B", "I"], "anims" => ["LEFT", "UP", "RIGHT", "UP", "LEFT", "DOWN", "RIGHT"],
			 "strumAnims" => ["LEFT", "UP", "RIGHT", "SPACE", "LEFT", "DOWN", "RIGHT"], "pixelAnimIndex" => [0, 2, 3, 4, 5, 1, 8], "sustaincolor" => ['c24b99', '12fa05', 'f9393f', 'cccccc', 'ffff00', '00ffff', '0033ff']],
		7 => ["letters" => ["A", "B", "C", "D", "F", "G", "H", "I"], "anims" => ["LEFT", "UP", "DOWN", "RIGHT", "LEFT", "DOWN", "UP", "RIGHT"],
			 "strumAnims" => ["LEFT", "DOWN", "UP", "RIGHT", "LEFT", "DOWN", "UP", "RIGHT"], "pixelAnimIndex" => [0, 1, 2, 3, 5, 6, 7, 8], "sustaincolor" => ['c24b99', '00ffff', '12fa05', 'f9393f', 'ffff00', '8b4aff', 'ff0000', '0033ff']],
		8 => ["letters" => ["A", "B", "C", "D", "E", "F", "G", "H", "I"], "anims" => ["LEFT", "DOWN", "UP", "RIGHT", "UP", "LEFT", "DOWN", "UP", "RIGHT"],
			 "strumAnims" => ["LEFT", "DOWN", "UP", "RIGHT", "SPACE", "LEFT", "DOWN", "UP", "RIGHT"], "pixelAnimIndex" => [0, 1, 2, 3, 4, 5, 6, 7, 8], "sustaincolor" => ['c24b99', '00ffff', '12fa05', 'f9393f', 'cccccc', 'ffff00', '8b4aff', 'ff0000', '0033ff']],
		9 => ["letters" => ["A", "B", "C", "D", "E", "J", "F", "G", "H", "I"], "anims" => ["LEFT", "DOWN", "UP", "RIGHT", "UP", "UP", "LEFT", "DOWN", "UP", "RIGHT"],
			 "strumAnims" => ["LEFT", "DOWN", "UP", "RIGHT", "SPACE", "CIRCLE", "LEFT", "DOWN", "UP", "RIGHT"], "pixelAnimIndex" => [0, 1, 2, 3, 4, 9, 5, 6, 7, 8], "sustaincolor" => ['c24b99', '00ffff', '12fa05', 'f9393f', 'cccccc', 'cccccc', 'ffff00', '8b4aff', 'ff0000', '0033ff']]
	];

	public static var ammo:Array<Int> = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
	public static var pixelScales:Array<Float> = [1.2, 1.15, 1.1, 1, 0.9, 0.83, 0.8, 0.74, 0.7, 0.6, 0.55];
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
	
	var defaultWidth:Float = 0;
	var defaultHeight:Float = 0;

	public function resizeByRatio(ratio:Float) { //haha funny twitter shit
		if(isSustainNote && !animation.curAnim.name.endsWith('end')) {
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
		if(texture != value) {
			reloadNote('', value);
		}
		texture = value;
		return value;
	}

	private function set_noteType(value:String):String {
		noteSplashTexture = PlayState.SONG.splashSkin;
		var arrowHSV:Array<Array<Int>> = ClientPrefs.getPref('arrowHSV');
		if (noteData > -1 && noteData < arrowHSV.length)
		{
			colorSwap.hue = arrowHSV[Std.int(Note.keysShit.get(mania).get('pixelAnimIndex')[noteData] % Note.ammo[mania])][0] / 360;
			colorSwap.saturation = arrowHSV[Std.int(Note.keysShit.get(mania).get('pixelAnimIndex')[noteData] % Note.ammo[mania])][1] / 100;
			colorSwap.brightness = arrowHSV[Std.int(Note.keysShit.get(mania).get('pixelAnimIndex')[noteData] % Note.ammo[mania])][2] / 100;
		}

		if(noteData > -1 && noteType != value) {
			switch(value) {
				case 'Hurt Note':
					ignoreNote = true;
					reloadNote('HURT');
					noteSplashTexture = 'HURTnoteSplashes';
					colorSwap.hue = 0;
					colorSwap.saturation = 0;
					colorSwap.brightness = 0;
					lowPriority = true;

					if(isSustainNote) {
						missHealth = 0.1;
					} else {
						missHealth = 0.3;
					}
					hitCausesMiss = true;
				case 'Danger Note':
					reloadNote('DANGER');
					noteSplashTexture = 'DANGERnoteSplashes';
					colorSwap.hue = 0;
					colorSwap.saturation = 0;
					colorSwap.brightness = 0;
					noMissAnimation = true;
					if(isSustainNote) {
						missHealth = 0.3;
					} else {
						missHealth = 0.5;
					}
					hitCausesMiss = false;
				case 'Kill Note':
					ignoreNote = true;
					reloadNote('KILL');
					noteSplashTexture = 'HURTnoteSplashes';
					colorSwap.hue = 0;
					colorSwap.saturation = 0;
					colorSwap.brightness = 0;
					missHealth = 1;
					hitCausesMiss = true;
				case 'Alt Animation':
					animSuffix = '-alt';
				case 'No Animation':
					noAnimation = true;
					noMissAnimation = true;
				case 'GF Sing':
					gfNote = true;
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
				var animToPlay:String = '';
				animToPlay = Note.keysShit.get(mania).get('letters')[noteData];
				animation.play(animToPlay);
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

	var lastNoteOffsetXForPixelAutoAdjusting:Float = 0;
	public var originalHeightForCalcs:Float = 6;
	function reloadNote(?prefix:String = '', ?texture:String = '', ?suffix:String = '') {
		if(prefix == null) prefix = '';
		if(texture == null) texture = '';
		if(suffix == null) suffix = '';

		var skin:String = texture;
		if(texture.length < 1) {
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

		defaultWidth = 157;
		defaultHeight = 154;
		if(PlayState.isPixelStage) {
			if(isSustainNote) {
				loadGraphic(Paths.image('pixelUI/' + blahblah + 'ENDS'));
				width = width / 10;
				height = height / 2;
				originalHeightForCalcs = height;
				loadGraphic(Paths.image('pixelUI/' + blahblah + 'ENDS'), true, Math.floor(width), Math.floor(height));
			} else {
				loadGraphic(Paths.image('pixelUI/' + blahblah));
				width = width / 10;
				height = height / 5;
				loadGraphic(Paths.image('pixelUI/' + blahblah), true, Math.floor(width), Math.floor(height));
			}
			defaultWidth = width;
			setGraphicSize(Std.int(width * PlayState.daPixelZoom * Note.pixelScales[mania]));
			loadPixelNoteAnims();
			antialiasing = false;

			if(isSustainNote) {
				offsetX += lastNoteOffsetXForPixelAutoAdjusting;
				lastNoteOffsetXForPixelAutoAdjusting = (width - 7) * (PlayState.daPixelZoom / 2);
				offsetX -= lastNoteOffsetXForPixelAutoAdjusting;
			}
		} else {
			frames = Paths.getSparrowAtlas(blahblah);
			loadNoteAnims();
			antialiasing = ClientPrefs.getPref('globalAntialiasing');
		}
		if(isSustainNote) {
			scale.y = lastScaleY;
		}
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
			else
				setGraphicSize(Std.int(defaultWidth * scales[mania]), Std.int(defaultHeight * scales[0]));

			updateHitbox();
		}
	}

	function loadPixelNoteAnims() {
		if(isSustainNote) {
			for (i in 0...gfxLetter.length) {
				animation.add(gfxLetter[i] + ' hold', [i]);
				animation.add(gfxLetter[i] + ' tail', [i + 10]);
			}
		} else {
			for (i in 0...gfxLetter.length) {
				animation.add(gfxLetter[i], [i + 10]);
			}
		}
	}

	public function applyManiaChange() {
		if (isSustainNote) 
			scale.y = 1;

		reloadNote(texture);
		if (isSustainNote)
			offsetX = width / 2;

		if (!isSustainNote) {
			var animToPlay:String = '';
			animToPlay = Note.keysShit.get(mania).get('letters')[noteData % Note.ammo[mania]];
			animation.play(animToPlay);
		}

		updateHitbox();
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
			else
				canBeHit = false;

			if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit)
				tooLate = true;
		} else {
			canBeHit = false;

			if (strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult)) {
				if ((isSustainNote && prevNote.wasGoodHit) || strumTime <= Conductor.songPosition)
					wasGoodHit = true;
			}
		}

		if (tooLate && !inEditor)
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}
	}
}