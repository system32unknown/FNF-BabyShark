package backend;

#if ACHIEVEMENTS_ALLOWED
import objects.AchievementPopup;
import haxe.Exception;
#if LUA_ALLOWED
import psychlua.FunkinLua;
#end

typedef Achievement = {
	var name:String;
	var description:String;
	@:optional var hidden:Bool;
	@:optional var maxScore:Float;
	@:optional var maxDecimals:Int;

	// handled automatically, ignore these two
	@:optional var mod:String;
	@:optional var ID:Int;
}

enum abstract AchievementOp(String) {
	var GET:AchievementOp = 'get';
	var SET:AchievementOp = 'set';
	var ADD:AchievementOp = 'add';
}

class Achievements {
	public static function init() {
		createAchievement('friday_night_play', 		{name: "Freaky on a Friday Night", description: "Play on a Friday... Night.", hidden: true});
		createAchievement('week1_nomiss',			{name: "She Calls Me Daddy Too", description: "Beat Week 1 on Hard with no Misses."});
		createAchievement('week2_nomiss',			{name: "No More Tricks", description: "Beat Week 2 on Hard with no Misses."});
		createAchievement('week3_nomiss',			{name: "Call Me The Hitman", description: "Beat Week 3 on Hard with no Misses."});
		createAchievement('week4_nomiss',			{name: "Lady Killer", description: "Beat Week 4 on Hard with no Misses."});
		createAchievement('week5_nomiss',			{name: "Missless Christmas", description: "Beat Week 5 on Hard with no Misses."});
		createAchievement('week6_nomiss',			{name: "Highscore!!", description: "Beat Week 6 on Hard with no Misses."});
		createAchievement('roadkill_enthusiast',	{name: "Roadkill Enthusiast", description: "Watch the Henchmen die 50 times.", maxScore: 50, maxDecimals: 0});
		createAchievement('ur_bad',					{name: "What a Funkin' Disaster!", description: "Complete a Song with a rating lower than 20%."});
		createAchievement('ur_good',				{name: "Perfectionist", description: "Complete a Song with a rating of 100%."});
		createAchievement('toastie',				{name: "Toaster Gamer", description: "Have you tried to run the game on a toaster?"});
		_originalLength = _sortID + 1; // dont delete this thing below
	}

	public static var achievements:Map<String, Achievement> = new Map<String, Achievement>();
	public static var variables:Map<String, Float> = [];
	public static var achievementsUnlocked:Array<String> = [];
	static var _firstLoad:Bool = true;

	public static function get(name:String):Achievement
		return achievements.get(name);

	public static function exists(name:String):Bool
		return achievements.exists(name);

	public static function load():Void {
		if (!_firstLoad) return;
		if (_originalLength < 0) init();

		if (FlxG.save.data != null) {
			if (FlxG.save.data.achievementsUnlocked != null)
				achievementsUnlocked = FlxG.save.data.achievementsUnlocked;

			var savedMap:Map<String, Float> = cast FlxG.save.data.achievementsVariables;
			if (savedMap != null) {
				for (key => value in savedMap) {
					variables.set(key, value);
				}
			}
			_firstLoad = false;
		}
	}

	public static function save():Void {
		FlxG.save.data.achievementsUnlocked = achievementsUnlocked;
		FlxG.save.data.achievementsVariables = variables;
	}

	public static function getScore(name:String):Float
		return _scoreFunc(name, GET);

	public static function setScore(name:String, value:Float, saveIfNotUnlocked:Bool = true):Float
		return _scoreFunc(name, SET, value, saveIfNotUnlocked);

	public static function addScore(name:String, value:Float = 1, saveIfNotUnlocked:Bool = true):Float
		return _scoreFunc(name, ADD, value, saveIfNotUnlocked);

	static function _scoreFunc(name:String, mode:AchievementOp, addOrSet:Float = 1, saveIfNotUnlocked:Bool = true):Float {
		if (!variables.exists(name)) variables.set(name, 0);

		if (achievements.exists(name)) {
			var achievement:Achievement = achievements.get(name);
			if (achievement.maxScore < 1) throw new Exception('Achievement has score disabled or is incorrectly configured: $name');

			if (achievementsUnlocked.contains(name)) return achievement.maxScore;

			var val:Float = addOrSet;
			switch (mode) {
				case GET: return variables.get(name); // get
				case ADD: val += variables.get(name); // add
				default:
			}

			if (val >= achievement.maxScore) {
				unlock(name);
				val = achievement.maxScore;
			}
			variables.set(name, val);

			Achievements.save();
			if (saveIfNotUnlocked || val >= achievement.maxScore)
				FlxG.save.flush();
			return val;
		}
		return -1;
	}

	static var _lastUnlock:Int = -999;
	public static function unlock(name:String, autoStartPopup:Bool = true):String {
		if (!achievements.exists(name)) {
			FlxG.log.error('Achievement "$name" does not exists!');
			throw new Exception('Achievement "$name" does not exists!');
			return null;
		}

		if (Achievements.isUnlocked(name)) return null;
		trace('Completed achievement "$name"');
		achievementsUnlocked.push(name);

		// earrape prevention
		var time:Int = openfl.Lib.getTimer();
		if (Math.abs(time - _lastUnlock) >= 100) { // If last unlocked happened in less than 100 ms (0.1s) ago, then don't play sound
			FlxG.sound.play(Paths.sound('confirmMenu'), .5);
			_lastUnlock = time;
		}

		Achievements.save();
		FlxG.save.flush();

		if (autoStartPopup) startPopup(name);
		return name;
	}

	inline public static function isUnlocked(name:String)
		return achievementsUnlocked.contains(name);

	@:allow(objects.AchievementPopup)
	private static var _popups:Array<AchievementPopup> = [];
	public static var showingPopups(get, never):Bool;

	public static function get_showingPopups():Bool
		return _popups.length > 0;

	public static function startPopup(achieve:String, endFunc:Void->Void = null) {
		for (popup in _popups) {
			if (popup == null) continue;
			popup.intendedY += 150;
		}
		_popups.push(new AchievementPopup(achieve, endFunc));
	}

	// Map sorting cuz haxe is physically incapable of doing that by itself
	static var _sortID = 0;
	static var _originalLength = -1;

	public static function createAchievement(name:String, data:Achievement, ?mod:String = null) {
		data.ID = _sortID;
		data.mod = mod;
		achievements.set(name, data);
		_sortID++;
	}

	#if MODS_ALLOWED
	public static function reloadList() {
		// remove modded achievements
		if ((_sortID + 1) > _originalLength)
			for (key => value in achievements)
				if (value.mod != null) achievements.remove(key);

		_sortID = _originalLength - 1;

		var modLoaded:String = Mods.currentModDirectory;
		Mods.currentModDirectory = null;
		loadAchievementJson(Paths.mods('data/achievements.json'));
		for (i => mod in Mods.parseList().enabled) {
			Mods.currentModDirectory = mod;
			loadAchievementJson(Paths.mods('$mod/data/achievements.json'));
		}
		Mods.currentModDirectory = modLoaded;
	}

	inline static function loadAchievementJson(path:String, addMods:Bool = true):Array<Dynamic> {
		var retVal:Array<Dynamic> = null;
        inline function errorMessage(title:String, message:String):Void {
            utils.system.NativeUtil.showMessageBox(message, title);
			Logs.trace('$title - $message', ERROR);
        }
		if (FileSystem.exists(path)) {
			try {
				var rawJson:String = File.getContent(path).trim();
				if (rawJson != null && rawJson.length > 0)
					retVal = tjson.TJSON.parse(rawJson);

				if (addMods && retVal != null) {
					for (i in 0...retVal.length) {
						var achieve:Dynamic = retVal[i];
						if (achieve == null) {
							errorMessage('Mod name: ' + Mods.currentModDirectory ?? "None", 'Achievement #${i + 1} is invalid.');
							continue;
						}

						var key:String = achieve.save;
						if (key == null || key.trim().length < 1) {
                            errorMessage('Error on Achievement: ' + (achieve.name ?? achieve.save), 'Missing valid "save" value.');
							continue;
						}
						key = key.trim();
						if (achievements.exists(key)) continue;
						createAchievement(key, achieve, Mods.currentModDirectory);
					}
				}
			} catch (e:Dynamic) errorMessage('Mod name: ' + Mods.currentModDirectory ?? "None", 'Error loading achievements.json: $e');
		}
		return retVal;
	}
	#end

	#if LUA_ALLOWED
	public static function addLuaCallbacks(lua:FunkinLua) {
		lua.set("getAchievementScore", function(name:String):Float {
			if (!achievements.exists(name)) {
				FunkinLua.luaTrace('getAchievementScore: Couldnt find achievement: $name', false, false, FlxColor.RED);
				return -1;
			}
			return getScore(name);
		});
		lua.set("setAchievementScore", function(name:String, ?value:Float = 0, ?saveIfNotUnlocked:Bool = true):Float {
			if (!achievements.exists(name)) {
				FunkinLua.luaTrace('setAchievementScore: Couldnt find achievement: $name', false, false, FlxColor.RED);
				return -1;
			}
			return setScore(name, value, saveIfNotUnlocked);
		});
		lua.set("addAchievementScore", function(name:String, ?value:Float = 1, ?saveIfNotUnlocked:Bool = true):Float {
			if (!achievements.exists(name)) {
				FunkinLua.luaTrace('addAchievementScore: Couldnt find achievement: $name', false, false, FlxColor.RED);
				return -1;
			}
			return addScore(name, value, saveIfNotUnlocked);
		});
		lua.set("unlockAchievement", function(name:String):Dynamic {
			if (!achievements.exists(name)) {
				FunkinLua.luaTrace('unlockAchievement: Couldnt find achievement: $name', false, false, FlxColor.RED);
				return null;
			}
			return unlock(name);
		});
		lua.set("isAchievementUnlocked", function(name:String):Dynamic {
			if (!achievements.exists(name)) {
				FunkinLua.luaTrace('isAchievementUnlocked: Couldnt find achievement: $name', false, false, FlxColor.RED);
				return null;
			}
			return isUnlocked(name);
		});
		lua.set("achievementExists", (name:String) -> return achievements.exists(name));
	}
	#end
}
#end