package objects;

import backend.animation.PsychAnimationController;
import animateatlas.AtlasFrameMaker;
import openfl.utils.Assets;
import haxe.Json;

typedef CharacterFile = {
	var animations:Array<AnimArray>;
	var image:String;
	var scale:Float;
	var sing_duration:Float;
	var healthicon:String;

	var position:Array<Float>;
	var camera_position:Array<Float>;

	var flip_x:Bool;
	var no_antialiasing:Bool;
	var healthbar_colors:Array<Int>;
}

typedef AnimArray = {
	var anim:String;
	var name:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Int>;
}

class Character extends FlxSprite {
	/**
	 * In case a character is missing, it will use this on its place
	**/
	public static final DEFAULT_CHARACTER:String = 'bf';
	public var animOffsets:Map<String, Array<Dynamic>>;
	public var debugMode:Bool = false;

	public var isPlayer:Bool = false;
	public var curCharacter:String = DEFAULT_CHARACTER;

	public var holdTimer:Float = 0;
	public var heyTimer:Float = 0;
	public var specialAnim:Bool = false;
	public var stunned:Bool = false;
	public var singDuration:Float = 4; //Multiplier of how long a character holds the sing pose
	public var idleSuffix:String = '';
	public var danceIdle:Bool = false; //Character use "danceLeft" and "danceRight" instead of "idle"
	public var skipDance:Bool = false;

	public var healthIcon:String = 'face';
	public var animationsArray:Array<AnimArray> = [];

	public var positionArray:Array<Float> = [0, 0];
	public var cameraPosition:Array<Float> = [0, 0];

	public var hasMissAnimations:Bool = false;

	//Used on Character Editor
	public var imageFile:String = '';
	public var jsonScale:Float = 1;
	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;
	public var healthColorArray:Array<Int> = [255, 0, 0];
	
	public function new(x:Float, y:Float, ?character:String = 'bf', ?isPlayer:Bool = false, ?library:String) {
		super(x, y);

		animation = new PsychAnimationController(this);

		animOffsets = new Map<String, Array<Dynamic>>();
		curCharacter = character;
		this.isPlayer = isPlayer;
		switch (curCharacter) {
			//case 'your character name in case you want to hardcode them instead':
			default:
				var json:CharacterFile = getCharacterFile(character);
				var spriteType:String = getSpriteType(json);

				switch (spriteType) {
					case "packer": frames = Paths.getPackerAtlas(json.image);
					case "sparrow": frames = Paths.getSparrowAtlas(json.image);
					case "texture": frames = AtlasFrameMaker.construct(json.image);
				}
				imageFile = json.image;

				if(json.scale != 1) {
					jsonScale = json.scale;
					setGraphicSize(Std.int(width * jsonScale));
					updateHitbox();
				}

				positionArray = json.position;
				cameraPosition = json.camera_position;

				healthIcon = json.healthicon;
				singDuration = json.sing_duration;
				flipX = (json.flip_x == true);
				if (json.no_antialiasing) {
					antialiasing = false;
					noAntialiasing = true;
				}

				if (json.healthbar_colors != null && json.healthbar_colors.length > 2)
					healthColorArray = json.healthbar_colors;

				if (!ClientPrefs.getPref('Antialiasing')) antialiasing = !noAntialiasing;

				animationsArray = json.animations;
				if (animationsArray != null && animationsArray.length > 0) {
					for (anim in animationsArray) {
						var animAnim:String = '' + anim.anim;
						var animName:String = '' + anim.name;
						var animFps:Int = anim.fps;
						var animLoop:Bool = !!anim.loop; //Bruh
						var animIndices:Array<Int> = anim.indices;
						if (animIndices != null && animIndices.length > 0)
							animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
						else animation.addByPrefix(animAnim, animName, animFps, animLoop);

						if(anim.offsets != null && anim.offsets.length > 1)
							addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
					}
				} else quickAnimAdd('idle', 'BF idle dance');
		}
		originalFlipX = flipX;

		if(animOffsets.exists('singLEFTmiss') || animOffsets.exists('singDOWNmiss') || animOffsets.exists('singUPmiss') || animOffsets.exists('singRIGHTmiss')) hasMissAnimations = true;
		recalculateDanceIdle();
		dance();

		if (isPlayer) flipX = !flipX;
	}

	public static function getCharacterFile(char:String):CharacterFile {
		var characterPath:String = 'characters/$char.json';

		#if MODS_ALLOWED
		var path:String = Paths.modFolders(characterPath);
		if (!FileSystem.exists(path))
			path = Paths.getPreloadPath(characterPath);

		if (!FileSystem.exists(path))
		#else
		var path:String = Paths.getPreloadPath(characterPath);
		if (!Assets.exists(path))
		#end
			path = Paths.getPreloadPath('characters/' + DEFAULT_CHARACTER + '.json'); //If a character couldn't be found, change him to BF just to prevent a crash

		var rawJson = #if MODS_ALLOWED File.getContent(path) #else Assets.getText(path) #end;
		try {
			var json:CharacterFile = cast Json.parse(rawJson);
			for (anim in json.animations)
				anim.indices = parseIndices(anim.indices);
			return json;
		} catch(e) Logs.trace('Error loading character "$char" JSON file', ERROR);
		return null;
	}

	public static function parseIndices(indices:Array<Any>):Array<Int> {
		var parsed:Array<Int> = [];
		for (val in indices) {
			if (val is Int) parsed.push(val);
			else if (val is String) {
				var val:String = cast val;
				var expression:Array<String> = val.split("..."); // might add something for "*" so you can repeat a frame a certain amount of times
				var startIndex:Null<Int> = Std.parseInt(expression[0]);
				var endIndex:Null<Int> = Std.parseInt(expression[1]);

				if (startIndex == null) 
					continue; // Can't do anything
				else if (endIndex == null) {
					parsed.push(startIndex); // hmm
					continue;
				}

				for (idxNumber in startIndex...(endIndex + 1))
					parsed.push(idxNumber);
			}
		}

		return parsed;
	}

	public static function getSpriteType(json:CharacterFile):String {
		var spriteType:String = "sparrow";

		#if MODS_ALLOWED
		var modTxtToFind:String = Paths.modsTxt(json.image);
		var txtToFind:String = Paths.getPath('images/' + json.image + '.txt', TEXT);

		if (FileSystem.exists(modTxtToFind) || FileSystem.exists(txtToFind) || Assets.exists(txtToFind))
		#else
		if (Assets.exists(Paths.getPath('images/' + json.image + '.txt', TEXT)))
		#end
			spriteType = "packer";

		#if MODS_ALLOWED
		var modAnimToFind:String = Paths.modFolders('images/' + json.image + '/Animation.json');
		var animToFind:String = Paths.getPath('images/' + json.image + '/Animation.json', TEXT);

		if (FileSystem.exists(modAnimToFind) || FileSystem.exists(animToFind) || Assets.exists(animToFind))
		#else
		if (Assets.exists(Paths.getPath('images/' + json.image + '/Animation.json', TEXT)))
		#end
			spriteType = "texture";

		return spriteType;
	}

	override function update(elapsed:Float) {
		if(!debugMode && animation.curAnim != null) {
			if (animation.curAnim.name.endsWith('miss') && animation.curAnim.finished)
				dance(true, false, 10);

			if (heyTimer > 0) {
				heyTimer -= elapsed * (PlayState.instance != null ? PlayState.instance.playbackRate : 1.0);
				if (heyTimer <= 0) {
					if (specialAnim && animation.curAnim.name == 'hey' || animation.curAnim.name == 'cheer') {
						specialAnim = false;
						dance();
					}
					heyTimer = 0;
				}
			} else if(specialAnim && animation.curAnim.finished) {
				specialAnim = false;
				dance();
			} else if (animation.curAnim.name.endsWith('miss') && animation.curAnim.finished) {
				dance();
				animation.finish();
			}

			if (animation.curAnim.name.startsWith('sing'))
				holdTimer += elapsed;
			else if(isPlayer) holdTimer = 0;

			var pitch = PlayState.instance != null ? PlayState.instance.playbackRate : FlxG.sound.music != null ? FlxG.sound.music.pitch : 1;
			if (!isPlayer && holdTimer >= Conductor.stepCrochet * (.0011 / pitch) * singDuration) {
				dance();
				holdTimer = 0;
			}

			if(animation.curAnim.finished && animation.getByName(animation.curAnim.name + '-loop') != null)
				playAnim('${animation.curAnim.name}-loop');
		}
		super.update(elapsed);
	}

	override function destroy() {
		animationsArray = null;
		animOffsets = null;
		shader = null;
		super.destroy();
	}

	/**
		*FOR GF DANCING SHIT
	**/
	public var danced:Bool = false;
	public function dance(force:Bool = false, reversed:Bool = false, frame:Int = 0) {
		if (!debugMode && !skipDance && !specialAnim) {
			var anim = 'idle';
			if (danceIdle) {
				danced = !danced;
				anim = danced ? 'danceRight' : 'danceLeft';
			}
			if(animation.getByName(anim + idleSuffix) != null)
				playAnim(anim + idleSuffix, force, reversed, frame);
		}
	}

	public function playAnim(animName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void {
		animation.play(animName, Force, Reversed, Frame);
		specialAnim = false;

		var daOffset = animOffsets.get(animName);
		if (animOffsets.exists(animName))
			offset.set(daOffset[0], daOffset[1]);
		else offset.set();

		if (danceIdle) {
			if (animName == 'singUP' || animName == 'singDOWN')
				danced = !danced;
			else if (animName.startsWith('sing'))
				danced = animName == 'singLEFT';
		}		
	}

	var settingCharacterUp:Bool = true;
	public var danceEveryNumBeats:Int = 2;
	public function recalculateDanceIdle() {
		var lastDanceIdle:Bool = danceIdle;
		danceIdle = (animation.getByName('danceLeft' + idleSuffix) != null && animation.getByName('danceRight' + idleSuffix) != null);

		if(settingCharacterUp) danceEveryNumBeats = danceIdle ? 1 : 2;
		else if(lastDanceIdle != danceIdle) {
			var calc:Float = danceEveryNumBeats;
			if(danceIdle) calc /= 2;
			else calc *= 2;

			danceEveryNumBeats = Math.round(Math.max(calc, 1));
		}
		settingCharacterUp = false;
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0) {
		animOffsets[name] = [x, y];
	}

	public function quickAnimAdd(name:String, anim:String) {
		animation.addByPrefix(name, anim, 24, false);
	}

	public function getColor():FlxColor {
		return CoolUtil.getColor(healthColorArray);
	}
}
