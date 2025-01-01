package objects;

import shaders.PixelSplashShader.PixelSplashShaderRef;
import shaders.RGBPalette;

typedef RGB = {
	r:Null<Int>,
	g:Null<Int>,
	b:Null<Int>
}

typedef NoteSplashAnim = {
	name:String,
	noteData:Int,
	prefix:String,
	indices:Array<Int>,
	offsets:Array<Float>,
	fps:Array<Int>
}

typedef NoteSplashConfig = {
	animations:Map<String, NoteSplashAnim>,
	scale:Float,
	allowRGB:Bool,
	allowPixel:Bool,
	rgb:Array<Null<RGB>>
}

class NoteSplash extends FlxSprite {
	public var rgbShader:PixelSplashShaderRef;
	public var texture:String;
	public var config(default, set):NoteSplashConfig;
	public var babyArrow:StrumNote;
	public var noteData:Int = 0;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var inEditor:Bool = false;

	var spawned:Bool = false;
	var noteDataMap:Map<Int, String> = new Map<Int, String>();

	public static var defaultNoteSplash(default, never):String = "noteSplashes/noteSplashes";
	public static var configs:Map<String, NoteSplashConfig> = new Map<String, NoteSplashConfig>();

	public function new(?x:Float = 0, ?y:Float = 0, ?splash:String) {
		super(x, y);

        animation = new backend.animation.PsychAnimationController(this);

		rgbShader = new PixelSplashShaderRef();
		shader = rgbShader.shader;

		loadSplash(splash);
	}

	public var maxAnims(default, set):Int = 0;
	public function loadSplash(?splash:String) {
		config = null;
		maxAnims = 0;

		texture = splash;
		frames = Paths.getSparrowAtlas(texture);
		if (frames == null) {
			texture = defaultNoteSplash + getSplashSkinPostfix();
			frames = Paths.getSparrowAtlas(texture);
			if (frames == null) {
				texture = defaultNoteSplash;
				frames = Paths.getSparrowAtlas(texture);
			}
		}

		var path:String = 'images/$texture';
		if (configs.exists(path)) {
			this.config = configs.get(path);
			for (anim in this.config.animations) {
				if (anim.noteData % EK.keys(PlayState.mania) == 0) maxAnims++;
			}
			return;
		} else if (Paths.fileExists('$path.json')) {
			var config:Dynamic = haxe.Json.parse(Paths.getTextFromFile('$path.json'));
			if (config != null) {
				var tempConfig:NoteSplashConfig = {
					animations: new Map<String, NoteSplashAnim>(),
					scale: config.scale,
					allowRGB: config.allowRGB,
					allowPixel: config.allowPixel,
					rgb: config.rgb
				}

				for (i in Reflect.fields(config.animations)) {
					var anim:NoteSplashAnim = Reflect.field(config.animations, i);
					tempConfig.animations.set(i, anim);
					if (anim.noteData % EK.keys(PlayState.mania) == 0) maxAnims++;
				}

				this.config = tempConfig;
				configs.set(path, this.config);
				return;
			}
		}

		// Splashes with no json
		var tempConfig:NoteSplashConfig = createConfig();
		var anim:String = 'note splash';
		var fps:Array<Null<Int>> = [22, 26];
		var offsets:Array<Array<Float>> = [[0, 0]];
		if (Paths.fileExists('$path.txt')) {  // Backwards compatibility with 0.7 splash txts
			var configFile:Array<String> = CoolUtil.listFromString(Paths.getTextFromFile('$path.txt'));
			if (configFile.length > 0) {
				anim = configFile[0];
				if (configFile.length > 1) {
					var framerates:Array<String> = configFile[1].split(' ');
					fps = [Std.parseInt(framerates[0]), Std.parseInt(framerates[1])];
					if (fps[0] == null) fps[0] = 22;
					if (fps[1] == null) fps[1] = 26;

					if (configFile.length > 2) {
						offsets = [];
						for (i in 2...configFile.length) {
							if (configFile[i].trim() != '') {
								var animOffs:Array<String> = configFile[i].split(' ');
								var x:Float = Std.parseFloat(animOffs[0]);
								var y:Float = Std.parseFloat(animOffs[1]);
								if (Math.isNaN(x)) x = 0;
								if (Math.isNaN(y)) y = 0;
								offsets.push([x, y]);
							}
						}
					}
				}
			}
		}

		var failedToFind:Bool = false;
		while (true) {
			for (v in EK.colArray) {
				if (!checkForAnim('$anim $v ${maxAnims + 1}')) {
					failedToFind = true;
					break;
				}
			}
			if (failedToFind) break;
			maxAnims++;
		}

		for (animNum in 0...maxAnims) {
			for (i => col in EK.colArray) {
				var data:Int = i % EK.colArray.length + (animNum * EK.colArray.length);
				var name:String = animNum > 0 ? '$col' + (animNum + 1) : col;
				var offset:Array<Float> = offsets[FlxMath.wrap(data, 0, Std.int(offsets.length - 1))];
				addAnimationToConfig(tempConfig, 1, name, '$anim $col ${animNum + 1}', fps, offset, [], data);
			}
		}

		this.config = tempConfig;
		configs.set(path, this.config);
	}

	public function spawnSplashNote(?x:Float = 0, ?y:Float = 0, ?noteData:Int = 0, ?note:Note, ?randomize:Bool = true) {	
		if (note != null && note.noteSplashData.disabled) return;
		aliveTime = 0;

		if (!inEditor) {
			var loadedTexture:String = defaultNoteSplash + getSplashSkinPostfix();
			if (note != null && note.noteSplashData.texture != null) loadedTexture = note.noteSplashData.texture;
			else if (PlayState.SONG != null && PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) loadedTexture = PlayState.SONG.splashSkin;

			if (texture != loadedTexture) loadSplash(loadedTexture);
		}

		setPosition(x, y);

		if (babyArrow != null) setPosition(babyArrow.x, babyArrow.y); // To prevent it from being misplaced for one game tick
		if (note != null) noteData = note.noteData;

		if (randomize && maxAnims > 1)
			noteData = noteData % EK.colArray.length + (FlxG.random.int(0, maxAnims - 1) * EK.colArray.length);

		this.noteData = noteData;
		var anim:String = playDefaultAnim();

		var tempShader:RGBPalette = null;
		if (config.allowRGB) {
			if (note == null) note = new Note().recycleNote(Note.DEFAULT_CAST);

			Note.initializeGlobalRGBShader(noteData % EK.colArray.length);
			function useDefault() {
				tempShader = Note.globalRgbShaders[noteData % EK.colArray.length];
			}

			if (inEditor || note.noteSplashData.useRGBShader && (PlayState.SONG == null || !PlayState.SONG.disableNoteRGB)) {
				tempShader = new RGBPalette();
				// If Note RGB is enabled:
				if (!note.noteSplashData.useGlobalShader || inEditor) {
					var colors:Array<RGB> = config.rgb;
					if (colors != null) {
						for (i in 0...colors.length) {
							if (i > 2) break;

							var arr:Array<FlxColor> = ClientPrefs.data.arrowRGBExtra[noteData % EK.gfxIndex[PlayState.mania][noteData]];
							if(PlayState.isPixelStage) arr = ClientPrefs.data.arrowRGBPixelExtra[noteData % EK.gfxIndex[PlayState.mania][noteData]];

							var rgb:RGB = colors[i];
							if (rgb == null) {
								if (i == 0) tempShader.r = arr[0];
								else if (i == 1) tempShader.g = arr[1];
								else if (i == 2) tempShader.b = arr[2];
								continue;
							}

							var r:Null<Int> = rgb.r; 
							var g:Null<Int> = rgb.g;
							var b:Null<Int> = rgb.b;

							if (r == null || Math.isNaN(r) || r < 0) r = arr[0];
							if (g == null || Math.isNaN(g) || g < 0) g = arr[1];
							if (b == null || Math.isNaN(b) || b < 0) b = arr[2];

							var color:FlxColor = FlxColor.fromRGB(r, g, b);
							if (i == 0) tempShader.r = color;
							else if (i == 1) tempShader.g = color;
							else if (i == 2) tempShader.b = color;
						}
					}
				} else tempShader.copyValues(Note.globalRgbShaders[noteData % EK.colArray.length]);

				if (note.noteSplashData.r == -1 && note.noteSplashData.g == -1 && note.noteSplashData.b == -1) tempShader = note.rgbShader.parent;
				else {
					if (note.noteSplashData.r != -1) tempShader.r = note.noteSplashData.r;
					if (note.noteSplashData.g != -1) tempShader.g = note.noteSplashData.g;
					if (note.noteSplashData.b != -1) tempShader.b = note.noteSplashData.b;
				}
			} else tempShader.copyValues(Note.globalRgbShaders[noteData % EK.colArray.length]);
		}
		rgbShader.copyValues(tempShader);

		if(!config.allowPixel) rgbShader.pixelAmount = 1;
		else if (PlayState.isPixelStage) rgbShader.pixelAmount = 6;

		var conf:NoteSplashAnim = config.animations.get(anim);
		var offsets:Array<Float> = [0, 0];

		if (conf != null) offsets = conf.offsets;

		if (offsets != null) {
			offset.x += offsets[0];
			offset.y += offsets[1];
		}

		animation.onFinish.add((_:String) -> {
			PlayState.instance != null ? killLimit() : kill();
			spawned = false;
		});
		
		alpha = ClientPrefs.data.splashAlpha;
		if (note != null) alpha = note.noteSplashData.a;

		antialiasing = ClientPrefs.data.antialiasing;
		if (note != null) antialiasing = note.noteSplashData.antialiasing;
		if (PlayState.isPixelStage && config.allowPixel) antialiasing = false;

		var minFps:Int = 22;
		var maxFps:Int = 26;
		if (conf != null) {
			minFps = conf.fps[0];
			if (minFps < 0) minFps = 0;

			maxFps = conf.fps[1];
			if (maxFps < 0) maxFps = 0;
		}

		if (animation.curAnim != null)
			animation.curAnim.frameRate = FlxG.random.int(minFps, maxFps);

		spawned = true;
	}

	public function playDefaultAnim() {
		var anim:String = noteDataMap.get(noteData);
		if (anim != null && animation.exists(anim))
			animation.play(anim, true);

		return anim;
	}

	function checkForAnim(anim:String) {
		var animFrames = [];
		@:privateAccess
		animation.findByPrefix(animFrames, anim); // adds valid frames to animFrames

		return animFrames.length > 0;
	}

	var aliveTime:Float = 0;
	static var buggedKillTime:Float = .5; //automatically kills note splashes if they break to prevent it from flooding your HUD
	override function update(elapsed:Float) {
		if (spawned) {
			aliveTime += elapsed;
			if (animation.curAnim == null && aliveTime >= buggedKillTime) {
				kill();
				spawned = false;
			}
		}

		if (babyArrow != null) {
			if (copyX) x = babyArrow.x - Note.originalWidth * .95;
			if (copyY) y = babyArrow.y - Note.originalWidth;
		}
		super.update(elapsed);
	}

    public static function getSplashSkinPostfix():String {
		var skin:String = '';
		if (ClientPrefs.data.splashSkin != ClientPrefs.defaultData.splashSkin)
			skin = '-' + ClientPrefs.data.splashSkin.trim().toLowerCase().replace(' ', '-');
		return skin;
	}

	public static function createConfig():NoteSplashConfig {
		return {
			animations: new Map<String, NoteSplashAnim>(),
			scale: 1,
			allowRGB: true,
			allowPixel: true,
			rgb: null
		}
	}

	public static function addAnimationToConfig(config:NoteSplashConfig, scale:Float, name:String, prefix:String, fps:Array<Int>, offsets:Array<Float>, indices:Array<Int>, noteData:Int):NoteSplashConfig {
		config ??= createConfig();
		config.animations.set(name, {name: name, noteData: noteData, prefix: prefix, indices: indices, offsets: offsets, fps: fps});
		config.scale = scale;
		return config;
	}

	function set_config(value:NoteSplashConfig):NoteSplashConfig  {
		value ??= createConfig();

		@:privateAccess
		animation.clearAnimations();
		noteDataMap.clear();

		for (i in value.animations) {
			var key:String = i.name;
			if (i.prefix.length > 0 && key != null && key.length > 0) {
				if (i.indices != null && i.indices.length > 0)
					animation.addByIndices(key, i.prefix, i.indices, "", i.fps[1], false);
				else animation.addByPrefix(key, i.prefix, i.fps[1], false);

				noteDataMap.set(i.noteData, key);
			}
		}

		scale.set(value.scale, value.scale);
		return config = value;
	}

	function set_maxAnims(value:Int):Int {
		if (value > 0) noteData = Std.int(FlxMath.wrap(noteData, 0, (value * EK.colArray.length) - 1));
		else noteData = 0;
		return maxAnims = value;
	}

	public function killLimit(targetId:Int = -1):Void {
		try {
			if (targetId != -1) PlayState.splashUsing[noteData].splice(targetId, 1);
			else PlayState.splashUsing[noteData].splice(0, 1);
		} catch (e) Logs.trace("something went wrong? " + e.message, WARNING);
		kill();
	}
}