package objects;

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
	@:optional var _editor_isPlayer:Null<Bool>;
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
	inline public static final DEFAULT_CHARACTER:String = 'bf';

	public var animOffsets:Map<String, Array<Float>>;
	public var debugMode:Bool = false;
	public var extraData:Map<String, Dynamic> = new Map<String, Dynamic>();

	public var isPlayer:Bool = false;
	public var curCharacter:String = DEFAULT_CHARACTER;

	public var holdTimer:Float = 0;
	public var heyTimer:Float = 0;
	public var specialAnim:Bool = false;
	public var stunned:Bool = false;
	public var singDuration:Float = 4; //Multiplier of how long a character holds the sing pose
	public var idleSuffix(default, set):String = '';
	public var danceIdle:Bool = false; //Character use "danceLeft" and "danceRight" instead of "idle"
	public var skipDance:Bool = false;

	public var healthIcon:String = 'face';
	public var animationsArray:Array<AnimArray> = [];

	public var positionArray:Array<Float> = [0, 0];
	public var cameraPosition:Array<Float> = [0, 0];
	public var healthColorArray:Array<Int> = [255, 0, 0];

	public var missingCharacter:Bool = false;
	public var missingText:FlxText;

	public var hasMissAnimations:Bool = false;

	//Used on Character Editor
	public var imageFile:String = '';
	public var jsonScale:Float = 1;
	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;
	public var editorIsPlayer:Null<Bool> = null;
	
	public function new(x:Float, y:Float, ?character:String = DEFAULT_CHARACTER, ?isPlayer:Bool = false, ?library:String) {
		super(x, y);

		animation = new backend.animation.PsychAnimationController(this);

		animOffsets = new Map<String, Array<Float>>();
		curCharacter = character;
		this.isPlayer = isPlayer;
		switch (curCharacter) {
			//case 'your character name in case you want to hardcode them instead':

			default:
				var path:String = Paths.getPath('characters/$curCharacter.json');
				
				if (!#if MODS_ALLOWED FileSystem #else Assets #end.exists(path)) {
					path = Paths.getSharedPath('characters/$DEFAULT_CHARACTER.json'); //If a character couldn't be found, change him to BF just to prevent a crash
					missingCharacter = true;
					missingText = new FlxText(0, 0, 300, 'ERROR:\n$curCharacter.json', 16);
					missingText.alignment = CENTER;
				}
		
				try {
					var json:CharacterFile = cast Json.parse(#if MODS_ALLOWED File.getContent #else Assets.getText #end(path));
					for (anim in json.animations) anim.indices = parseIndices(anim.indices);
					loadCharacterFile(json);
				} catch(e) Logs.trace('Error loading character file of "$curCharacter": $e', ERROR);
		}

		for (name => _ in animOffsets)
			if (name.startsWith('sing') && name.contains('miss')) { // includes alt miss animations now
				hasMissAnimations = true;
				break;
			}
		recalculateDanceIdle();
		dance();
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

				if (startIndex == null) continue; // Can't do anything
				else if (endIndex == null) {
					parsed.push(startIndex); // hmm
					continue;
				}

				for (idxNumber in startIndex...(endIndex + 1)) parsed.push(idxNumber);
			}
		}

		return parsed;
	}

	public function loadCharacterFile(json:Dynamic) {
		isAnimateAtlas = false;

		#if flxanimate
		var animToFind:String = Paths.getPath('images/${json.image}/Animation.json');
		if (#if MODS_ALLOWED FileSystem.exists(animToFind) || #end Assets.exists(animToFind))
			isAnimateAtlas = true;
		#end

		scale.set(1, 1);
		updateHitbox();

		if(!isAnimateAtlas) frames = Paths.getAtlas(json.image);
		#if flxanimate
		else {
			atlas = new FlxAnimate();
			atlas.showPivot = false;
			try {
				Paths.loadAnimateAtlas(atlas, json.image);
			} catch(e:Dynamic) FlxG.log.warn('Could not load atlas ${json.image}: $e');
		}
		#end

		imageFile = json.image;
		jsonScale = json.scale;
		if(json.scale != 1) {
			scale.set(jsonScale, jsonScale);
			updateHitbox();
		}

		positionArray = json.position;
		cameraPosition = json.camera_position;

		healthIcon = json.healthicon;
		singDuration = json.sing_duration;
		flipX = (json.flip_x != isPlayer);
		healthColorArray = (json.healthbar_colors != null && json.healthbar_colors.length > 2) ? json.healthbar_colors : [161, 161, 161];
		originalFlipX = (json.flip_x == true);
		editorIsPlayer = json._editor_isPlayer;

		// antialiasing
		noAntialiasing = (json.no_antialiasing == true);
		antialiasing = ClientPrefs.data.antialiasing ? !noAntialiasing : false;

		animationsArray = json.animations;
		if (animationsArray != null && animationsArray.length > 0) {
			for (anim in animationsArray) {
				var animAnim:String = '' + anim.anim;
				var animName:String = '' + anim.name;
				var animFps:Int = anim.fps;
				var animLoop:Bool = !!anim.loop; //Bruh
				var animIndices:Array<Int> = anim.indices;

				if(!isAnimateAtlas) {
					if(animIndices != null && animIndices.length > 0)
						animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
					else animation.addByPrefix(animAnim, animName, animFps, animLoop);
				}
				#if flxanimate
				else {
					if(animIndices != null && animIndices.length > 0)
						atlas.anim.addBySymbolIndices(animAnim, animName, animIndices, animFps, animLoop);
					else atlas.anim.addBySymbol(animAnim, animName, animFps, animLoop);
				}
				#end
	
				if(anim.offsets != null && anim.offsets.length > 1) addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
				else addOffset(anim.anim);
			}
		}
		#if flxanimate if(isAnimateAtlas) copyAtlasValues(); #end
	}

	override function update(elapsed:Float) {
		if(isAnimateAtlas) atlas.update(elapsed);

		if(debugMode || (!isAnimateAtlas && animation.curAnim == null) || (isAnimateAtlas && atlas.anim.curSymbol == null)) {
			super.update(elapsed);
			return;
		}

		if (heyTimer > 0) {
			heyTimer -= elapsed * (PlayState.instance != null ? PlayState.instance.playbackRate : 1.0);
			if (heyTimer <= 0) {
				var anim:String = getAnimationName();
				if(specialAnim && (anim == 'hey' || anim == 'cheer')) {
					specialAnim = false;
					dance();
				}
				heyTimer = 0;
			}
		} else if(specialAnim && isAnimationFinished()) {
			specialAnim = false;
			dance();
		} else if(getAnimationName().endsWith('miss') && isAnimationFinished()) {
			dance();
			finishAnimation();
		}
		
		if (getAnimationName().startsWith('sing')) holdTimer += elapsed;
		else if(isPlayer) holdTimer = 0;

		if (!isPlayer && holdTimer >= Conductor.stepCrochet * (.0011 / (PlayState.instance != null ? PlayState.instance.playbackRate : FlxG.sound.music != null ? FlxG.sound.music.pitch : 1)) * singDuration) {
			dance();
			holdTimer = 0;
		}

		var name:String = getAnimationName();
		if(isAnimationFinished() && animOffsets.exists('$name-loop'))
			playAnim('$name-loop');

		super.update(elapsed);
	}

	inline public function isAnimationNull():Bool
		return !isAnimateAtlas ? (animation.curAnim == null) : (atlas.anim.curSymbol == null);

	inline public function getAnimationName():String {
		var name:String = '';
		@:privateAccess
		if(!isAnimationNull()) name = !isAnimateAtlas ? animation.curAnim.name : atlas.anim.lastPlayedAnim;
		return (name != null) ? name : '';
	}

	public function isAnimationFinished():Bool {
		if(isAnimationNull()) return false;
		return !isAnimateAtlas ? animation.curAnim.finished : atlas.anim.finished;
	}

	public function finishAnimation():Void {
		if(isAnimationNull()) return;

		if(!isAnimateAtlas) animation.curAnim.finish();
		else atlas.anim.curFrame = atlas.anim.length - 1;
	}

	public var animPaused(get, set):Bool;
	function get_animPaused():Bool {
		if(isAnimationNull()) return false;
		return !isAnimateAtlas ? animation.curAnim.paused : atlas.anim.isPlaying;
	}
	function set_animPaused(value:Bool):Bool {
		if(isAnimationNull()) return value;
		if(!isAnimateAtlas) animation.curAnim.paused = value;
		else {
			if(value) atlas.anim.pause();
			else atlas.anim.resume();
		} 

		return value;
	}

	/**
		*FOR GF DANCING SHIT
	**/
	public var danced:Bool = false;
	public function dance(force:Bool = false, reversed:Bool = false, frame:Int = 0) {
		if (debugMode || skipDance || specialAnim) return;

		var anim = 'idle';
		if (danceIdle) {
			danced = !danced;
			anim = danced ? 'danceRight' : 'danceLeft';
		}
		if(animOffsets.exists(anim + idleSuffix))
			playAnim(anim + idleSuffix, force, reversed, frame);
	}

	public function playAnim(animName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void {
		if (animation.getByName(animName) == null) return;
		specialAnim = false;

		if(!isAnimateAtlas) animation.play(animName, Force, Reversed, Frame);
		else atlas.anim.play(animName, Force, Reversed, Frame);

		if (animOffsets.exists(animName)) {
			final daOffset = animOffsets.get(animName);
			offset.set(daOffset[0], daOffset[1]);
		}

		if (danceIdle) {
			if (animName == 'singUP' || animName == 'singDOWN')
				danced = !danced;
			else if (animName.startsWith('sing'))
				danced = animName == 'singLEFT';
		}		
	}

	public var danceEveryNumBeats:Int = 2;
	var settingCharacterUp:Bool = true;
	public function recalculateDanceIdle() {
		final lastDanceIdle:Bool = danceIdle;
		danceIdle = (animOffsets.exists('danceLeft' + idleSuffix) && animOffsets.exists('danceRight' + idleSuffix));

		if(settingCharacterUp) danceEveryNumBeats = danceIdle ? 1 : 2;
		else if(lastDanceIdle != danceIdle) {
			var calc:Float = danceEveryNumBeats;
			if(danceIdle) calc /= 2;
			else calc *= 2;

			danceEveryNumBeats = Math.round(Math.max(calc, 1));
		}
		settingCharacterUp = false;
	}

	function set_idleSuffix(newSuffix:String):String {
		if (idleSuffix == newSuffix) return newSuffix;

		idleSuffix = newSuffix;
		recalculateDanceIdle();
		return idleSuffix;
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0) {
		animOffsets[name] = [x, y];
	}

	// Atlas support
	// special thanks ne_eo for the references, you're the goat!!
	public var isAnimateAtlas:Bool = false;
	#if flxanimate
	public var atlas:FlxAnimate;
	public override function draw() {
		var lastAlpha:Float = alpha;
		var lastColor:FlxColor = color;
		if(missingCharacter)
		{
			alpha *= 0.6;
			color = FlxColor.BLACK;
		}

		if(isAnimateAtlas) {
			copyAtlasValues();
			atlas.draw();
			if(missingCharacter) {
				alpha = lastAlpha;
				color = lastColor;

				missingText.setPosition(getMidpoint().x - 150, getMidpoint().y - 10);
				missingText.draw();
			}
		}
		super.draw();
		if(missingCharacter) {
			alpha = lastAlpha;
			color = lastColor;
			missingText.setPosition(getMidpoint().x - 150, getMidpoint().y - 10);
			missingText.draw();
		}
	}

	public function copyAtlasValues() {
		@:privateAccess {
			atlas.cameras = cameras;
			atlas.scrollFactor = scrollFactor;
			atlas.scale = scale;
			atlas.offset = offset;
			atlas.origin = origin;
			atlas.x = x;
			atlas.y = y;
			atlas.angle = angle;
			atlas.alpha = alpha;
			atlas.visible = visible;
			atlas.flipX = flipX;
			atlas.flipY = flipY;
			atlas.shader = shader;
			atlas.antialiasing = antialiasing;
			atlas.colorTransform = colorTransform;
			atlas.color = color;
		}
	}

	public override function destroy() {
		super.destroy();
		destroyAtlas();
	}

	public function destroyAtlas() {
		if (atlas != null) atlas = flixel.util.FlxDestroyUtil.destroy(atlas);
	}
	#end
}
