package data;

#if !MODS_ALLOWED import openfl.utils.Assets; #end
import scripting.ModchartSprite;
import backend.Song;
import tjson.TJSON;

typedef StageFile = {
	var directory:String;
	var defaultZoom:Float;
	@:optional var isPixelStage:Null<Bool>;
	var stageUI:String;
	@default(["intro3", "intro2", "intro1", "introGo"])
	var introSounds:Array<String>;

	var boyfriend:Array<Dynamic>;
	var girlfriend:Array<Dynamic>;
	var opponent:Array<Dynamic>;
	var hide_girlfriend:Bool;

	var camera_boyfriend:Array<Float>;
	var camera_opponent:Array<Float>;
	var camera_girlfriend:Array<Float>;
	var camera_speed:Null<Float>;

	@:optional var preload:Dynamic;
	@:optional var objects:Array<Dynamic>;
	@:optional var _editorMeta:Dynamic;
}

enum abstract LoadFilters(Int) from Int from UInt to Int to UInt {
	var LOW_QUALITY:Int = (1 << 0);
	var HIGH_QUALITY:Int = (1 << 1);

	var STORY_MODE:Int = (1 << 2);
	var FREEPLAY:Int = (1 << 3);
}

class StageData {
	public static function dummy():StageFile {
		return {
			directory: "",
			defaultZoom: .9,
			isPixelStage: false,
			stageUI: "normal",
			introSounds: ["intro3", "intro2", "intro1", "introGo"],

			boyfriend: [770, 100],
			girlfriend: [400, 130],
			opponent: [100, 100],
			hide_girlfriend: false,

			camera_boyfriend: [0, 0],
			camera_opponent: [0, 0],
			camera_girlfriend: [0, 0],
			camera_speed: 1,

			_editorMeta: {
				gf: "gf",
				dad: "dad",
				boyfriend: "bf"
			}
		};
	}

	public static var forceNextDirectory:String = null;
	public static function loadDirectory(SONG:SwagSong) {
		var stage:String = '';
		if (SONG.stage != null) stage = SONG.stage;
		else if (Song.loadedSongName != null) stage = vanillaSongStage(Paths.formatToSongPath(SONG.song));
		else stage = 'stage';

		var stageFile:StageFile = getStageFile(stage);
		forceNextDirectory = (stageFile != null) ? stageFile.directory : ''; // preventing crashes
	}

	public static function getStageFile(stage:String):StageFile {
		try {
			var path:String = Paths.getPath('stages/$stage.json');
			#if MODS_ALLOWED
			if (FileSystem.exists(path)) return cast TJSON.parse(File.getContent(path));
			#else
			if (Assets.exists(path)) return cast TJSON.parse(Assets.getText(path));
			#end
		}
		return dummy();
	}

	public static function vanillaSongStage(songName):String {
		return switch (songName) {
			case 'spookeez' | 'south' | 'monster': 'spooky';
			case 'pico' | 'blammed' | 'philly' | 'philly-nice': 'philly';
			case 'milf' | 'satin' | 'high': 'limo';
			case 'cocoa' | 'eggnog': 'mall';
			case 'home' | 'swirling' | 'dimensional': 'davehouse';
			default: 'stage';
		}
	}

	public static var reservedNames:Array<String> = ['gf', 'gfGroup', 'dad', 'dadGroup', 'boyfriend', 'boyfriendGroup']; // blocks these names from being used on stage editor's name input text
	public static function addObjectsToState(objectList:Array<Dynamic>, gf:FlxSprite, dad:FlxSprite, boyfriend:FlxSprite, ?group:Dynamic = null, ?ignoreFilters:Bool = false):Map<String, FlxSprite> {
		var addedObjects:Map<String, FlxSprite> = [];
		for (num => data in objectList) {
			if (addedObjects.exists(data)) continue;

			switch (data.type) {
				case 'gf', 'gfGroup':
					if (gf != null) {
						gf.ID = num;
						if (group != null) group.add(gf);
						addedObjects.set('gf', gf);
					}
				case 'dad', 'dadGroup':
					if (dad != null) {
						dad.ID = num;
						if (group != null) group.add(dad);
						addedObjects.set('dad', dad);
					}
				case 'boyfriend', 'boyfriendGroup':
					if (boyfriend != null) {
						boyfriend.ID = num;
						if (group != null) group.add(boyfriend);
						addedObjects.set('boyfriend', boyfriend);
					}

				case 'square', 'sprite', 'animatedSprite':
					if (!ignoreFilters && !validateVisibility(data.filters)) continue;

					var spr:ModchartSprite = new ModchartSprite(data.x, data.y);
					spr.ID = num;
					if (data.type != 'square') {
						if (data.type == 'sprite') spr.loadGraphic(Paths.image(data.image));
						else spr.frames = Paths.getAtlas(data.image);

						if (data.type == 'animatedSprite' && data.animations != null) {
							var anims:Array<objects.Character.AnimArray> = cast data.animations;
							for (key => anim in anims) {
								if (anim.indices == null || anim.indices.length < 1)
									spr.animation.addByPrefix(anim.anim, anim.name, anim.fps, anim.loop);
								else spr.animation.addByIndices(anim.anim, anim.name, anim.indices, '', anim.fps, anim.loop);

								if (anim.offsets != null)
									spr.addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);

								if (spr.animation.curAnim == null || data.firstAnimation == anim.anim)
									spr.playAnim(anim.anim, true);
							}
						}
						for (varName in ['antialiasing', 'flipX', 'flipY']) {
							var dat:Dynamic = Reflect.getProperty(data, varName);
							if (dat != null) Reflect.setProperty(spr, varName, dat);
						}
						if (!Settings.data.antialiasing) spr.antialiasing = false;
					} else {
						spr.makeGraphic(1, 1);
						spr.antialiasing = false;
					}

					if (data.scale != null && (data.scale[0] != 1. || data.scale[1] != 1.)) {
						spr.scale.set(data.scale[0], data.scale[1]);
						spr.updateHitbox();
					}
					spr.scrollFactor.set(data.scroll[0], data.scroll[1]);
					spr.color = Util.colorFromString(data.color);
					spr.blend = scripting.ScriptUtils.blendModeFromString(data.blend);

					for (varName in ['alpha', 'angle']) {
						var dat:Dynamic = Reflect.getProperty(data, varName);
						if (dat != null) Reflect.setProperty(spr, varName, dat);
					}

					if (group != null) group.add(spr);
					addedObjects.set(data.name, spr);

				default: FlxG.log.error('[Stage .JSON file] Unknown sprite type detected: ${data.type}');
			}
		}
		return addedObjects;
	}

	public static function validateVisibility(filters:LoadFilters):Bool {
		if ((filters & STORY_MODE) == STORY_MODE) if (!PlayState.isStoryMode) return false;
		else if ((filters & FREEPLAY) == FREEPLAY) if (PlayState.isStoryMode) return false;

		return ((Settings.data.lowQuality && (filters & LOW_QUALITY) == LOW_QUALITY) || (!Settings.data.lowQuality && (filters & HIGH_QUALITY) == HIGH_QUALITY));
	}
}