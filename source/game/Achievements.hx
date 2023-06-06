package game;

#if MODS_ALLOWED
import sys.io.File;
import sys.FileSystem;
#end

typedef AchievementMeta = {
	public var name:String;
	public var desc:String;
	public var save_tag:String;
	public var hidden:Bool;
	public var ?song:String;

	public var ?week_nomiss:String;
	public var ?lua_code:String;
	/**
		If null or -1, gets pushed instead of getting inserting to specified index.
	**/
	public var ?index:Int;
	/**
		If not null, replaces achievements completely.
		
		Using global is dangerous and it should be used just once in a modpack.
	**/
	public var ?global:Array<Dynamic>;
	/**
	    If true, clears the vanilla achievements.
		
		Same goes for clearAchievements, it should be used just once in a modpack and global should be null aswell.
	**/
	public var ?clearAchievements:Bool; 
}

class Achievements {
	public static var achievementsStuff:Array<Dynamic> = [ //Name, Description, Achievement save tag, Hidden achievement
		["Freaky on a Friday Night",	"Play on a Friday... Night.",						'friday_night_play',	 true],
		["The Tooth dentist Downfall",	"Beat Week 1 on Hard with no Misses.",				'week1_nomiss',			false],
		["No More Tricks",				"Beat Week 2 on Hard with no Misses.",				'week2_nomiss',			false],
		["Call Me The Hitman",			"Beat Week 3 on Hard with no Misses.",				'week3_nomiss',			false],
		["The Pinky Mommy Shark",		"Beat Week 4 on Hard with no Misses.",				'week4_nomiss',			false],
		["Missless Christmas",			"Beat Week 5 on Hard with no Misses.",				'week5_nomiss',			false],
		["Pixelin Perfect!",			"Beat Week 6 on Hard with no Misses.",				'week6_nomiss',			false],
		["What a Funkin' Disaster!",	"Complete a Song with a rating lower than 20%.",	'ur_bad',				false],
		["Perfectionist",				"Complete a Song with a rating of 100%.",			'ur_good',				false],
		["Oversinging Much...?",		"Hold down a note for 10 seconds.",					'oversinging',			false],
		["Hyperactive",					"Finish a Song without going Idle.",				'hype',					false],
		["Just the Two of Us",			"Finish a Song pressing only two keys.",			'two_keys',				false],
	];
	public static var copyAchievements = achievementsStuff.copy();
	public static var achievementsMap:Map<String, Bool> = new Map<String, Bool>();

	public static function unlockAchievement(name:String):Void {
		FlxG.log.add('Completed achievement "' + name +'"');
		achievementsMap.set(name, true);
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
	}

	public static function isAchievementUnlocked(name:String) {
		if(achievementsMap.exists(name) && achievementsMap.get(name)) {
			return true;
		}
		return false;
	}

	public static function exists(name:String) {
		for (i in achievementsStuff) {
			if (i[2] == name) return true;
		}
		return false;
	}

	public static function getAchievementIndex(name:String) {
		for (i in 0...achievementsStuff.length) {
			if (achievementsStuff[i][2] == name) {
				return i;
			}
		}
		return -1;
	}

	public static function loadAchievements():Void {
		#if (MODS_ALLOWED && ACHIEVEMENTS_ALLOWED)
		loadModAchievements();
		#end

		if(FlxG.save.data != null) {
			if(FlxG.save.data.achievementsMap != null) {
				achievementsMap = FlxG.save.data.achievementsMap;
			}
		}
	}


	#if (MODS_ALLOWED && ACHIEVEMENTS_ALLOWED)
	public static function loadModAchievements() {
		achievementsStuff = copyAchievements.copy();
		var paths:Array<String> = [Paths.modFolders('achievements/'), Paths.getPreloadPath('achievements/'),];
		for (i in paths.copy()) {
			if (FileSystem.exists(i)) {
				for (l in FileSystem.readDirectory(i)) {
					if (l.endsWith('.json')) {
						var meta:AchievementMeta = cast haxe.Json.parse(File.getContent(i + l));
						if (meta != null) {
							if (meta.global != null && meta.global.length > 0 && !FileSystem.exists(i + l.substring(0, l.length - 4) + 'lua'))
								throw '($l) global needs a lua file to work.\nCreate a lua file named \"' + l.substring(0, l.length - 5) + "\" in \"" + i + "\".";

							if (meta.global == null || meta.global.length < 1) {
								if (meta.clearAchievements) achievementsStuff = [];
								var achievement:Array<Dynamic> = [];
								achievement.push(meta.name);
								achievement.push(meta.desc);
								achievement.push(meta.save_tag);
								achievement.push(meta.hidden);
								var index:Null<Int> = meta.index;
								if (!achievementsStuff.contains(achievement)) {
									if (index == null || index < 0)
										achievementsStuff.push(achievement.copy());
									else achievementsStuff.insert(index, achievement);
								}
							} else achievementsStuff = meta.global.copy();
						}
					}
				}
			}
		}
	}

	public static function getModAchievements():Array<String> {
		var paths:Array<String> = [Paths.modFolders('achievements/'), Paths.getPreloadPath('achievements/'),];
		var luas:Array<String> = [];
		for (i in paths) {
			if (FileSystem.exists(i)) {
				for (l in FileSystem.readDirectory(i)) {
					var pushedLuas = [];
					var file = l.substr(0, l.length - 4);
					//ignore lua files that does not have a json file
					if (l.endsWith('.lua') && FileSystem.exists(i + file + '.json') && !pushedLuas.contains(l)) {
						luas.push(i + l);
						pushedLuas.push(l);
					}
				}
			}
		}
		return luas.copy();
	}

	public static function getModAchievementMetas():Array<AchievementMeta> {
		var paths:Array<String> = [Paths.modFolders('achievements/'), Paths.getPreloadPath('achievements/'),];
		var metas = [];
		for (i in paths)
			if (FileSystem.exists(i))
				for (l in FileSystem.readDirectory(i))
					if (l.endsWith('.json')) {
						try {
							var meta:AchievementMeta = haxe.Json.parse(File.getContent(i + l));
							metas.push(meta);
						} catch(e) trace(e.stack);
					}
		return metas;
	}
	#end
}

class AttachedAchievement extends FlxSprite {
	public var sprTracker:FlxSprite;
	private var tag:String;
	public function new(x:Float = 0, y:Float = 0, name:String) {
		super(x, y);

		changeAchievement(name);
		antialiasing = ClientPrefs.getPref('Antialiasing');
	}

	public function changeAchievement(tag:String) {
		this.tag = tag;
		reloadAchievementImage();
	}

	public function reloadAchievementImage() {
		if(Achievements.isAchievementUnlocked(tag)) {
			loadGraphic(Paths.image('achievements/' + tag));
		} else loadGraphic(Paths.image('achievements/lockedachievement'));
		scale.set(.7, .7);
		updateHitbox();
	}

	override function update(elapsed:Float) {
		if (sprTracker != null)
			setPosition(sprTracker.x - 130, sprTracker.y + 25);

		super.update(elapsed);
	}
}

class AchievementObject extends FlxSpriteGroup {
	public var onFinish:Void->Void = null;
	var alphaTween:FlxTween;
	public function new(name:String, ?camera:FlxCamera = null)
	{
		super(x, y);
		ClientPrefs.saveSettings();

		var id:Int = Achievements.getAchievementIndex(name);
		var achievementBG:FlxSprite = new FlxSprite(60, 50).makeGraphic(420, 120, FlxColor.BLACK);
		achievementBG.scrollFactor.set();

		var achievementIcon:FlxSprite = new FlxSprite(achievementBG.x + 10, achievementBG.y + 10).loadGraphic(Paths.image('achievements/' + name));
		achievementIcon.scrollFactor.set();
		achievementIcon.setGraphicSize(Std.int(achievementIcon.width * (2 / 3)));
		achievementIcon.updateHitbox();
		achievementIcon.antialiasing = ClientPrefs.getPref('Antialiasing');

		var achievementName:FlxText = new FlxText(achievementIcon.x + achievementIcon.width + 20, achievementIcon.y + 16, 280, Achievements.achievementsStuff[id][0], 16);
		achievementName.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		achievementName.scrollFactor.set();

		var achievementText:FlxText = new FlxText(achievementName.x, achievementName.y + 32, 280, Achievements.achievementsStuff[id][1], 16);
		achievementText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		achievementText.scrollFactor.set();

		add(achievementBG);
		add(achievementName);
		add(achievementText);
		add(achievementIcon);

		@:privateAccess
		var cam:Array<FlxCamera> = FlxG.cameras.defaults;
		if(camera != null) cam = [camera];
		alpha = 0;
		achievementBG.cameras = cam;
		achievementName.cameras = cam;
		achievementText.cameras = cam;
		achievementIcon.cameras = cam;
		alphaTween = FlxTween.tween(this, {alpha: 1}, 0.5, {onComplete: function (twn:FlxTween) {
			alphaTween = FlxTween.tween(this, {alpha: 0}, 0.5, {
				startDelay: 2.5,
				onComplete: function(twn:FlxTween) {
					alphaTween = null;
					remove(this);
					if(onFinish != null) onFinish();
				}
			});
		}});
	}

	override function destroy() {
		if(alphaTween != null) {
			alphaTween.cancel();
		}
		super.destroy();
	}
}