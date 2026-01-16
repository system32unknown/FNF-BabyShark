package objects;

import haxe.Json;

typedef CharacterFile = {
	var animations:Array<AnimArray>;
	var image:flixel.util.typeLimit.OneOfTwo<String, Array<String>>;
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
	@:optional var isFrameLabel:Bool;
}

enum CharacterSpriteType {
	SPRITE;
	MULTI_ATLAS;
	TEXTURE_ATLAS;
}

class Character extends FlxAnimate {
	/**
	 * In case a character is missing, it will use this on its place
	 */
	public static inline final DEFAULT_CHARACTER:String = 'bf';

	public var animOffsets:Map<String, Array<Float>>;
	public var debugMode:Bool = false;
	public var extraData:Map<String, Dynamic> = new Map<String, Dynamic>();

	public var isPlayer:Bool = false;
	public var isMultiAtlas:Bool = false;
	public var curCharacter:String = DEFAULT_CHARACTER;

	public var holdTimer:Float = 0;
	public var heyTimer:Float = 0;
	public var specialAnim:Bool = false;
	public var stunned:Bool = false;
	public var singDuration:Float = 4; // Multiplier of how long a character holds the sing pose
	public var idleSuffix(default, set):String = '';
	public var danceIdle:Bool = false; // Character use "danceLeft" and "danceRight" instead of "idle"
	public var skipDance:Bool = false;

	public var healthIcon:String = 'face';
	public var animationsArray:Array<AnimArray> = [];

	public var positionArray:Array<Float> = [0, 0];
	public var cameraPosition:Array<Float> = [0, 0];
	public var healthColorArray:Array<Int> = [255, 0, 0];

	public var missingCharacter:Bool = false;
	public var missingText:FlxText;

	public var hasMissAnimations:Bool = false;

	// Used on Character Editor
	public var imageFile:String = '';
	public var jsonScale:Float = 1;
	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;
	public var editorIsPlayer:Null<Bool> = null;
	public var isAnimateAtlas:Bool = false;

	public var spriteType:CharacterSpriteType = SPRITE;

	public var prevCrochet:Float;
	public var charCrochet:Float;

	final targetCrochet:Float = .075;

	public function new(x:Float, y:Float, ?character:String, ?isPlayer:Bool = false, ?library:String) {
		character ??= DEFAULT_CHARACTER;
		super(x, y);

		animOffsets = new Map<String, Array<Float>>();
		this.isPlayer = isPlayer;
		changeCharacter(character);

		prevCrochet = Conductor.stepCrochet;
		charCrochet = prevCrochet / 1000.;
	}

	public function changeCharacter(character:String) {
		animationsArray = [];
		animOffsets = [];
		curCharacter = character;

		var path:String = Paths.getPath('characters/$curCharacter.json');
		if (!Paths.exists(path)) {
			path = Paths.getSharedPath('characters/$DEFAULT_CHARACTER.json'); // If a character couldn't be found, change him to BF just to prevent a crash
			missingCharacter = true;
			missingText = new FlxText(0, 0, 300, 'ERROR:\n$character.json', 16);
			missingText.alignment = CENTER;
		}

		try {
			loadCharacterFile(Json.parse(#if MODS_ALLOWED File.getContent #else Assets.getText #end(path)));
		} catch (e:Dynamic) Logs.error('Error loading character file of "$curCharacter": $e');

		skipDance = false;

		for (name => _ in animOffsets)
			if (name.startsWith('sing') && name.contains('miss')) { // includes alt miss animations now
				hasMissAnimations = true;
				break;
			}

		recalculateDanceIdle();
		dance();
	}

	override public function isOnScreen(?camera:FlxCamera):Bool {
		if (spriteType == MULTI_ATLAS) return true;
		if (camera == null) camera = FlxG.camera;

		return camera.containsRect(getScreenBounds(_rect, camera));
	}

	public function loadCharacterFile(json:Dynamic) {
		scale.set(1, 1);
		updateHitbox();

		if (!(json.image is String)) {
			spriteType = MULTI_ATLAS;
			isAnimateAtlas = false;
			isMultiAtlas = true;
			frames = Paths.getAtlas(json.image[0]);
			final split:Array<String> = json.image;
			if (frames != null)
				for (imgFile in split) {
					final daAtlas = Paths.getAtlas(imgFile);
					if (daAtlas != null) cast(frames, flixel.graphics.frames.FlxAtlasFrames).addAtlas(daAtlas);
				}
			imageFile = json.image[0];
		} else {
			if (!Paths.fileExists('images/${json.image}.png', IMAGE)) {
				spriteType = TEXTURE_ATLAS;
				isAnimateAtlas = true;
				isMultiAtlas = false;
				frames = Paths.getTextureAtlas(json.image);
			} else {
				spriteType = SPRITE;
				isMultiAtlas = isAnimateAtlas = false;
				frames = Paths.getAtlas(json.image);
			}
			imageFile = json.image;
		}

		jsonScale = json.scale;
		if (json.scale != 1) {
			scale.set(jsonScale, jsonScale);
			updateHitbox();
		}

		// positioning
		positionArray = json.position;
		cameraPosition = json.camera_position;

		// data
		healthIcon = json.healthicon;
		singDuration = json.sing_duration;
		flipX = (json.flip_x != isPlayer);
		healthColorArray = (json.healthbar_colors != null && json.healthbar_colors.length > 2) ? json.healthbar_colors : [161, 161, 161];
		originalFlipX = (json.flip_x == true);
		editorIsPlayer = json._editor_isPlayer;

		// antialiasing
		noAntialiasing = (json.no_antialiasing == true);
		antialiasing = Settings.data.antialiasing ? !noAntialiasing : false;

		// animations
		animationsArray = json.animations;
		if (animationsArray != null && animationsArray.length > 0) {
			for (anim in animationsArray) {
				var animAnim:String = '' + anim.anim;
				var animName:String = '' + anim.name;
				var animFps:Int = anim.fps;
				var animLoop:Bool = !!anim.loop; // Bruh
				var animIndices:Array<Int> = anim.indices;

				switch (spriteType)
				{
					case TEXTURE_ATLAS:
						if (anim.isFrameLabel) {
							if (animIndices != null && animIndices.length > 0)
								this.anim.addByFrameLabelIndices(animAnim, animName, animIndices, animFps, animLoop);
							else this.anim.addByFrameLabel(animAnim, animName, animFps, animLoop);
						} else {
							if (animIndices != null && animIndices.length > 0)
								this.anim.addBySymbolIndices(animAnim, animName, animIndices, animFps, animLoop);
							else this.anim.addBySymbol(animAnim, animName, animFps, animLoop);
						}
					default:
						if (animIndices != null && animIndices.length > 0)
							this.anim.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
						else this.anim.addByPrefix(animAnim, animName, animFps, animLoop);
				}

				if (anim.offsets != null && anim.offsets.length > 1)
					addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
				else
					addOffset(anim.anim);
			}
		}
	}

	override function update(elapsed:Float) {
		if (debugMode || isAnimationNull()) {
			super.update(elapsed);
			return;
		}

		if (heyTimer > 0) {
			heyTimer -= elapsed * (PlayState.instance != null ? PlayState.instance.playbackRate : 1.);
			if (heyTimer <= 0) {
				var anim:String = getAnimationName();
				if (specialAnim && (anim == 'hey' || anim == 'cheer')) {
					specialAnim = false;
					dance();
				}
				heyTimer = 0;
			}
		} else if (specialAnim && isAnimationFinished()) {
			specialAnim = false;
			dance();
		} else if (getAnimationName().endsWith('miss') && isAnimationFinished()) {
			dance();
			finishAnimation();
		}

		if (getAnimationName().startsWith('sing')) holdTimer += elapsed;
		else if (isPlayer) holdTimer = 0;

		if (prevCrochet != Conductor.stepCrochet) {
			prevCrochet = Conductor.stepCrochet;
			charCrochet = prevCrochet / 1000.;
		}

		do {
			if (charCrochet < targetCrochet) charCrochet *= 2.;
			else break;
		} while (true);

		if (!isPlayer && holdTimer >= charCrochet * singDuration) {
			dance();
			holdTimer = 0;
		}

		var name:String = getAnimationName();
		if (isAnimationFinished() && hasAnimation('$name-loop')) playAnim('$name-loop');

		super.update(elapsed);
	}

	inline public function isAnimationNull():Bool
		return anim.curAnim == null;

	inline public function getAnimationName():String {
		var name:String = '';
		@:privateAccess
		if (!isAnimationNull()) name = anim.curAnim.name;
		return name ?? '';
	}

	public function isAnimationFinished():Bool {
		if (isAnimationNull()) return false;
		return anim.curAnim.finished;
	}

	public function finishAnimation():Void {
		if (isAnimationNull()) return;
		animation.curAnim.finish();
	}

	inline public function hasAnimation(anim:String):Bool {
		return animOffsets.exists(anim);
	}

	public var animPaused(get, set):Bool;
	function get_animPaused():Bool {
		if (isAnimationNull()) return false;
		return anim.curAnim.paused;
	}

	function set_animPaused(value:Bool):Bool {
		if (isAnimationNull()) return value;
		anim.curAnim.paused = value;

		return value;
	}

	public var danced:Bool = false;

	/**
	 * FOR GF DANCING SHIT
	 */
	public function dance(force:Bool = false, reversed:Bool = false, frame:Int = 0) {
		if (debugMode || skipDance || specialAnim) return;

		var anim:String = 'idle';
		if (danceIdle) {
			danced = !danced;
			anim = danced ? 'danceRight' : 'danceLeft';
		}
		if (hasAnimation(anim + idleSuffix)) playAnim(anim + idleSuffix, force, reversed, frame);
	}

	public function playAnim(animName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void {
		if (animation.getByName(animName) == null) return;

		specialAnim = false;
		anim.play(animName, Force, Reversed, Frame);

		if (hasAnimation(animName)) {
			final daOffset:Array<Float> = animOffsets.get(animName);
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
		danceIdle = (hasAnimation('danceLeft' + idleSuffix) && hasAnimation('danceRight' + idleSuffix));

		if (settingCharacterUp) danceEveryNumBeats = danceIdle ? 1 : 2;
		else if (lastDanceIdle != danceIdle) {
			var calc:Float = danceEveryNumBeats;
			if (danceIdle) calc /= 2;
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

	public function addOffset(name:String, x:Float = 0, y:Float = 0):Void {
		animOffsets[name] = [x, y];
	}

	public function quickAnimAdd(name:String, anim:String):Void {
		if (spriteType == TEXTURE_ATLAS)
			this.anim.addBySymbol(name, name, 24, false);
		else this.anim.addByPrefix(name, anim, 24, false);
	}
}