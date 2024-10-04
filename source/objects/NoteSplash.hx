package objects;

import shaders.PixelSplashShader.PixelSplashShaderRef;
import shaders.RGBPalette;
import states.editors.NoteSplashEditorState;

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
	public var skin:String;
	public var config(default, set):NoteSplashConfig;

	public static var DEFAULT_SKIN:String = "noteSplashes/noteSplashes";
	public static var configs:Map<String, NoteSplashConfig> = new Map();

	public var babyArrow:StrumNote;
	var noteDataMap:Map<Int, String> = new Map();

	public function new(?splash:String) {
		super();

        animation = new backend.animation.PsychAnimationController(this);

		rgbShader = new PixelSplashShaderRef();
		shader = rgbShader.shader;

		loadSplash(splash);
	}

	function loadSplash(?splash:String) {
		config = null; // Reset config to the default so when reloaded it can be set properly
		skin = null;

		var skin:String = splash;
		if (skin == null || skin.length < 1) skin = try PlayState.SONG.splashSkin catch(e) null;
		if (skin == null || skin.length < 1) skin = DEFAULT_SKIN + getSplashSkinPostfix();

		this.skin = skin;

		try frames = Paths.getSparrowAtlas(skin) catch (e) {
			skin = DEFAULT_SKIN; // The splash skin was not found, return to the default
			this.skin = skin;
			try frames = Paths.getSparrowAtlas(skin) catch (e) {
				active = visible = false;
			}
		}

		var path:String = 'images/$skin.json';
		if (configs.exists(path)) this.config = configs.get(path);
		else if (Paths.fileExists(path)) {
			var config:Dynamic = haxe.Json.parse(Paths.getTextFromFile(path));
			if (config != null) {
				var tempConfig:NoteSplashConfig = {
					animations: new Map(),
					scale: config.scale,
					allowRGB: config.allowRGB,
					allowPixel: config.allowPixel,
					rgb: config.rgb
				}

				for (i in Reflect.fields(config.animations)) tempConfig.animations.set(i, Reflect.field(config.animations, i));

				this.config = tempConfig;
				configs.set(path, tempConfig);
			}
		}
	}

	public function spawnSplashNote(note:Note, ?noteData:Int, ?randomize:Bool = true) {	
		if (note != null && note.noteSplashData.texture != null) loadSplash(note.noteSplashData.texture);
		if (note != null && note.noteSplashData.disabled) return;

		if (babyArrow != null) setPosition(babyArrow.x, babyArrow.y); // To prevent it from being misplaced for one game tick

		var noteData:Null<Int> = noteData;
		if (noteData == null) noteData = note != null ? note.noteData : 0;

		if (randomize) {
			var anims:Int = 0;
			var datas:Int = 0;
			var animArray:Array<Int> = [];

			while (true) {
				var data:Int = noteData % 4 + (datas * 4); 
				if (!noteDataMap.exists(data) || !animation.exists(noteDataMap[data])) break;

				datas++;
				anims++;
			}

			if (anims > 1) {
				for (i in 0...anims) {
					var data:Int = noteData % 4 + (i * 4);
					if (!animArray.contains(data)) animArray.push(data);
				}
			}

			if (animArray.length > 1) noteData = animArray[FlxG.random.bool() ? 0 : 1];
		}

		var anim:String = null;
		function playDefaultAnim() {
			var animation:String = noteDataMap.get(noteData);
			if (animation != null && this.animation.exists(animation)) {
				this.animation.play(animation);
				anim = animation;
			} else visible = false;
		}

		playDefaultAnim();

		var tempShader:RGBPalette = null;
		if (config.allowRGB) {
			if (note == null) note = new Note(0, noteData);

			Note.initializeGlobalRGBShader(noteData % 4);
			function useDefault() {
				tempShader = Note.globalRgbShaders[noteData % 4];
			}

			if(((cast FlxG.state) is NoteSplashEditorState) ||  ((note.noteSplashData.useRGBShader) && (PlayState.SONG == null || !PlayState.SONG.disableNoteRGB))) {
				// If Note RGB is enabled:
				if((!note.noteSplashData.useGlobalShader || ((cast FlxG.state) is NoteSplashEditorState))) {
					var colors = config.rgb;
					if (colors != null) {
						tempShader = new RGBPalette();
						for (i in 0...colors.length) {
							if (i > 2) break;

							var arr:Array<FlxColor> = ClientPrefs.data.arrowRGB[noteData % 4];
							if(PlayState.isPixelStage) arr = ClientPrefs.data.arrowRGBPixel[noteData % 4];

							var rgb = colors[i];
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
					} else useDefault();
				} else useDefault();
			}
		}
		rgbShader.copyValues(tempShader);

		if(!config.allowPixel) rgbShader.pixelAmount = 1;

		var conf:NoteSplashAnim = config.animations.get(anim);
		var offsets:Array<Float> = [0, 0];

		if (conf != null) offsets = conf.offsets;

		if (offsets != null) {
			centerOffsets();
			offset.set(offsets[0], offsets[1]);
		}

		animation.onFinish.add((_:String) -> kill());
		
        alpha = ClientPrefs.data.splashAlpha;
		if(note != null) alpha = note.noteSplashData.a;

		if(note != null) antialiasing = note.noteSplashData.antialiasing;
		if(PlayState.isPixelStage) antialiasing = false;

		if(animation.curAnim != null && conf != null) {
			var minFps:Int = conf.fps[0];
			if (minFps < 0) minFps = 0;

			var maxFps:Int = conf.fps[1];
			if (maxFps < 0) maxFps = 0;

			animation.curAnim.frameRate = FlxG.random.int(minFps, maxFps);
		}
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		if (babyArrow != null) setPosition(babyArrow.x, babyArrow.y);
	}

    public static function getSplashSkinPostfix():String {
		var skin:String = '';
		if(ClientPrefs.data.splashSkin != ClientPrefs.defaultData.splashSkin)
			skin = '-' + ClientPrefs.data.splashSkin.trim().toLowerCase().replace(' ', '-');
		return skin;
	}

	public static function createConfig():NoteSplashConfig {
		return {
			animations: new Map(),
			scale: 1,
			allowRGB: true,
			allowPixel: true,
			rgb: null
		}
	}

	public static function addAnimationToConfig(config:NoteSplashConfig, scale:Float, name:String, prefix:String, fps:Array<Int>, offsets:Array<Float>, indices:Array<Int>, noteData:Int):NoteSplashConfig {
		if (config == null) config = createConfig();

		config.animations.set(name, {name: name, noteData: noteData, prefix: prefix, indices: indices, offsets: offsets, fps: fps});
		config.scale = scale;
		return config;
	}

	function set_config(value:NoteSplashConfig):NoteSplashConfig  {
		if (value == null) value = createConfig();

		noteDataMap.clear();

		for (i in value.animations) {
			var key:String = i.name;
			if (i.prefix.length > 0 && key != null && key.length > 0) {
				if (i.indices != null && i.indices.length > 0 && key != null && key.length > 0)
					animation.addByIndices(key, i.prefix, i.indices, "", i.fps[1], false);
				else animation.addByPrefix(key, i.prefix, i.fps[1], false);

				noteDataMap.set(i.noteData, key);
			}
		}

		scale.set(value.scale, value.scale);
		return config = value;
	}
}