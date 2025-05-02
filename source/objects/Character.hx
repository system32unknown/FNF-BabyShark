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
	 */
	public static inline final DEFAULT_CHARACTER:String = 'bf';

	public var animOffsets:Map<String, Array<Float>>;
	public var debugMode:Bool = false;
	public var extraData:Map<String, Dynamic> = new Map<String, Dynamic>();

	public var isPlayer:Bool = false;
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

	public var prevCrochet:Float;
	public var charaCrochet:Float;

	final targetCrochet:Float = .075;

	public function new(x:Float, y:Float, ?character:String, ?isPlayer:Bool = false, ?library:String) {
		character ??= DEFAULT_CHARACTER;
		super(x, y);

		animation = new backend.animation.PsychAnimationController(this);

		animOffsets = new Map<String, Array<Float>>();
		this.isPlayer = isPlayer;
		changeCharacter(character);

		prevCrochet = Conductor.stepCrochet;
		charaCrochet = prevCrochet / 1000.;
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
		} catch (e:Dynamic) Logs.trace('Error loading character file of "$curCharacter": $e', ERROR);

		skipDance = false;
		for (name => _ in animOffsets)
			if (name.startsWith('sing') && name.contains('miss')) { // includes alt miss animations now
				hasMissAnimations = true;
				break;
			}
		recalculateDanceIdle();
		dance();
	}

	public function loadCharacterFile(json:Dynamic) {
		isAnimateAtlas = false;

		var path:String = json.assetPath == null ? json.image : json.assetPath.replace('shared:', '');
		#if flxanimate
		var animToFind:String = Paths.getPath('images/$path/Animation.json');
		if (#if MODS_ALLOWED FileSystem.exists(animToFind) || #end Assets.exists(animToFind))
			isAnimateAtlas = true;
		#end

		scale.set(1, 1);
		updateHitbox();

		if (!isAnimateAtlas) {
			if (json.assetPath != null) path = convertMultiSparrow(json.animations, path);
			frames = Paths.getMultiAtlas(path.split(','));
		}
		#if flxanimate
		else {
			atlas = new FlxAnimate();
			atlas.showPivot = false;
			try {
				Paths.loadAnimateAtlas(atlas, path);
			} catch (e:haxe.Exception) FlxG.log.warn('Could not load atlas $path: $e');
		}
		#end

		if (json.assetPath == null) {
			imageFile = json.image;
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
		} else {
			imageFile = json.assetPath.replace('shared:', '');
			imageFile = convertMultiSparrow(json.animations, imageFile);

			if (json.scale != null) {
				jsonScale = json.scale;
				if (json.scale != 1) {
					scale.set(jsonScale, jsonScale);
					updateHitbox();
				}
			}

			// positioning
			if (json.offsets != null) positionArray = json.offsets;
			if (json.cameraOffsets != null) cameraPosition = json.cameraOffsets;

			// data
			if (json.healthIcon != null) healthIcon = json.healthIcon.id != null ? json.healthIcon.id : curCharacter;
			else healthIcon = curCharacter;

			if (json.singTime != null) singDuration = json.singTime;
			else singDuration = 8.0;

			if (json.flipX != null) flipX = (json.flipX != isPlayer);

			// place holder icon to grab the color.
			var icon:HealthIcon = new HealthIcon(healthIcon, false, false);
			var coolColor:FlxColor = FlxColor.fromInt(utils.SpriteUtil.dominantColor(icon));
			icon.destroy();
			icon = null;
			healthColorArray[0] = coolColor.red;
			healthColorArray[1] = coolColor.green;
			healthColorArray[2] = coolColor.blue;

			originalFlipX = (json.flipX == true);

			// antialiasing
			noAntialiasing = json.isPixel ?? false;
			antialiasing = Settings.data.antialiasing ? !noAntialiasing : false;

			// animations
			var base_animationsArray:Array<Dynamic> = [];
			base_animationsArray = json.animations;
			if (base_animationsArray != null && base_animationsArray.length > 0) {
				for (anim in base_animationsArray) {
					animationsArray.push({
						anim: anim.name,
						name: anim.prefix,
						fps: anim.fps ?? 24,
						loop: anim.loop != null ? !!anim.loop : false,
						indices: anim.indices != null ? anim.indices : [],
						offsets: anim.offsets != null ? anim.offsets : [0, 0]
					});
				}
			}
		}

		if (animationsArray != null && animationsArray.length > 0) {
			for (anim in animationsArray) {
				var animAnim:String = '' + anim.anim;
				var animName:String = '' + anim.name;
				var animFps:Int = anim.fps;
				var animLoop:Bool = !!anim.loop; // Bruh
				var animIndices:Array<Int> = anim.indices;

				if (!isAnimateAtlas) {
					if (animIndices != null && animIndices.length > 0)
						animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
					else animation.addByPrefix(animAnim, animName, animFps, animLoop);
				}
				#if flxanimate
				else {
					if (animIndices != null && animIndices.length > 0)
						atlas.anim.addBySymbolIndices(animAnim, animName, animIndices, animFps, animLoop);
					else atlas.anim.addBySymbol(animAnim, animName, animFps, animLoop);
				}
				#end

				if (anim.offsets != null && anim.offsets.length > 1) addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
				else addOffset(anim.anim);
			}
		}
		#if flxanimate if (isAnimateAtlas) copyAtlasValues(); #end
	}

	function convertMultiSparrow(animations:Null<Array<Dynamic>>, str:String):String {
		if (animations != null && animations.length > 0) {
			for (anim in animations) {
				if (anim.assetPath != null && anim.assetPath != '')
					str += ',${anim.assetPath.replace('shared:', '')}';
			}
		}
		return str;
	}

	override function update(elapsed:Float) {
		if (isAnimateAtlas) atlas.update(elapsed);
		if (debugMode || (!isAnimateAtlas && animation.curAnim == null) || (isAnimateAtlas && (atlas.anim.curInstance == null || atlas.anim.curSymbol == null))) {
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
			charaCrochet = prevCrochet / 1000.;
		}

		do {
			if (charaCrochet < targetCrochet) charaCrochet *= 2.;
			else break;
		} while (true);
		if (!isPlayer && holdTimer >= charaCrochet * singDuration) {
			dance();
			holdTimer = 0;
		}

		var name:String = getAnimationName();
		if (isAnimationFinished() && hasAnimation('$name-loop')) playAnim('$name-loop');

		super.update(elapsed);
	}

	inline public function isAnimationNull():Bool {
		return !isAnimateAtlas ? (animation.curAnim == null) : (atlas.anim.curInstance == null || atlas.anim.curSymbol == null);
	}

	var _lastPlayedAnimation:String;
	inline public function getAnimationName():String {
		return _lastPlayedAnimation;
	}

	public function isAnimationFinished():Bool {
		if (isAnimationNull()) return false;
		return !isAnimateAtlas ? animation.curAnim.finished : atlas.anim.finished;
	}

	public function finishAnimation():Void {
		if (isAnimationNull()) return;

		if (!isAnimateAtlas) animation.curAnim.finish();
		else atlas.anim.curFrame = atlas.anim.length - 1;
	}

	public function hasAnimation(anim:String):Bool {
		return animOffsets.exists(anim);
	}

	public var animPaused(get, set):Bool;
	function get_animPaused():Bool {
		if (isAnimationNull()) return false;
		return !isAnimateAtlas ? animation.curAnim.paused : atlas.anim.isPlaying;
	}

	function set_animPaused(value:Bool):Bool {
		if (isAnimationNull()) return value;
		if (!isAnimateAtlas) animation.curAnim.paused = value;
		else {
			if (value) atlas.pauseAnimation();
			else atlas.resumeAnimation();
		}

		return value;
	}

	/**
	 * FOR GF DANCING SHIT
	 */
	public var danced:Bool = false;

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
		if (animation.getByName(animName) == null && !isAnimateAtlas) return;
		specialAnim = false;

		if (!isAnimateAtlas) animation.play(animName, Force, Reversed, Frame);
		else {
			atlas.anim.play(animName, Force, Reversed, Frame);
			atlas.update(0);
		}
		_lastPlayedAnimation = animName;

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

	public function addOffset(name:String, x:Float = 0, y:Float = 0) {
		animOffsets[name] = [x, y];
	}

	// Atlas support
	// special thanks ne_eo for the references, you're the goat!!
	@:allow(states.editors.CharacterEditorState)
	public var isAnimateAtlas(default, null):Bool = false;
	#if flxanimate
	public var atlas:FlxAnimate;

	public override function draw() {
		var lastAlpha:Float = alpha;
		var lastColor:FlxColor = color;
		if (missingCharacter && visible) {
			alpha *= 0.6;
			color = FlxColor.BLACK;
		}

		if (isAnimateAtlas) {
			if (atlas.anim.curInstance != null) {
				copyAtlasValues();
				atlas.draw();
				alpha = lastAlpha;
				color = lastColor;
				if (missingCharacter && visible) {
					missingText.setPosition(getMidpoint().x - 150, getMidpoint().y - 10);
					missingText.draw();
				}
			}
			return;
		}

		super.draw();
		if (missingCharacter && visible) {
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
			atlas.setPosition(x, y);
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
		atlas = flixel.util.FlxDestroyUtil.destroy(atlas);
		super.destroy();
	}
	#end
}