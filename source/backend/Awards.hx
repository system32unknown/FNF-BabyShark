package backend;

#if AWARDS_ALLOWED
import objects.AchievementPopup;
import flixel.util.FlxSave;

typedef Award = {
	var name:String;
	var description:String;
	var ?hidden:Bool;
	var ?maxScore:Float;
	var ?maxDecimals:Int;

	// handled automatically, ignore these two
	var ?mod:String;
	var ?ID:Int; 
}

enum abstract AchievementOp(String) {
	var GET:AchievementOp = 'get';
	var SET:AchievementOp = 'set';
	var ADD:AchievementOp = 'add';
}

class Awards {
	public static function init() {
		createAchievement('week1_nomiss', {name: "She Calls Me Daddy Too", description: "Beat Week 1 on Hard with no Misses."});
		createAchievement('week2_nomiss', {name: "No More Tricks", description: "Beat Week 2 on Hard with no Misses."});
		createAchievement('week3_nomiss', {name: "Call Me The Hitman", description: "Beat Week 3 on Hard with no Misses."});
		createAchievement('week4_nomiss', {name: "Lady Killer", description: "Beat Week 4 on Hard with no Misses."});
		createAchievement('week5_nomiss', {name: "Missless Christmas", description: "Beat Week 5 on Hard with no Misses."});
		createAchievement('week6_nomiss', {name: "Highscore!!", description: "Beat Week 6 on Hard with no Misses."});
		createAchievement('week7_nomiss', {name: "God Effing Damn It!", description: "Beat Week 7 on Hard with no Misses."});
		createAchievement('ur_bad', {name: "What a Funkin' Disaster!", description: "Complete a Song with a rating lower than 20%."});
		createAchievement('ur_good', {name: "Perfectionist", description: "Complete a Song with a rating of 100%."});
		createAchievement('toastie', {name: "Toaster Gamer", description: "Have you tried to run the game on a toaster?"});

		// dont delete this thing below
		_originalLength = _sortID + 1;
	}

	public static function get(name:String):Award return list[name];
	public static function exists(name:String):Bool return list.exists(name);

	public static var list:Map<String, Award> = new Map<String, Award>();
	public static var variables:Map<String, Float> = [];
	public static var unlocked:Array<String> = [];

	static var _firstLoad:Bool = true;
	static var _save:FlxSave;

	public static function load():Void {
		if (!_firstLoad) return;
		if (_originalLength < 0) init();

		_save = new FlxSave();
		_save.bind('awards', Util.getSavePath());

		if (_save.data == null) return;
		if (_save.data.unlocked != null) unlocked = _save.data.unlocked;

		var savedMap:Map<String, Float> = _save.data.variables;
		if (savedMap != null) for (key => value in savedMap) variables.set(key, value);
		_firstLoad = false;
	}

	public static function save():Void {
		_save.data.unlocked = unlocked;
		_save.data.variables = variables;
	}

	public static function getScore(name:String):Float
		return _scoreFunc(name, GET);

	public static function setScore(name:String, value:Float, ?saveIfNotUnlocked:Bool = true):Float
		return _scoreFunc(name, SET, value, saveIfNotUnlocked);

	public static function addScore(name:String, ?value:Float = 1, ?saveIfNotUnlocked:Bool = true):Float
		return _scoreFunc(name, ADD, value, saveIfNotUnlocked);

	static function _scoreFunc(name:String, mode:AchievementOp, ?addOrSet:Float = 1, ?saveIfNotUnlocked:Bool = true):Float {
		if (!variables.exists(name)) variables.set(name, 0);

		if (list.exists(name)) {
			var achievement:Award = list[name];
			if (achievement.maxScore < 1) {
				Sys.println('Achievement has score disabled or is incorrectly configured: $name');
				return 0.0;
			}

			if (unlocked.contains(name)) return achievement.maxScore;

			var val:Float = addOrSet;
			switch (mode) {
				case GET: return variables[name]; // get
				case ADD: val += variables[name]; // add
				default:
			}

			if (val >= achievement.maxScore) {
				unlock(name);
				val = achievement.maxScore;
			}
			variables.set(name, val);

			save();
			if (saveIfNotUnlocked || val >= achievement.maxScore) _save.flush();
			return val;
		}
		return -1;
	}

	static var _lastUnlock:Int = -999;
	public static function unlock(name:String, autoStartPopup:Bool = true):String {
		if (!list.exists(name)) {
			Sys.println('Achievement "$name" does not exist!');
			return null;
		}

		if (isUnlocked(name)) return null;
		trace('Completed achievement "$name"');
		unlocked.push(name);

		// earrape prevention
		var time:Int = openfl.Lib.getTimer();
		if (Math.abs(time - _lastUnlock) >= 100) { // If last unlocked happened in less than 100 ms (0.1s) ago, then don't play sound
			FlxG.sound.play(Paths.sound('confirmMenu'), .5);
			_lastUnlock = time;
		}

		save();
		_save.flush();

		if (autoStartPopup) startPopup(name);
		return name;
	}

	public static function isUnlocked(name:String):Bool
		return unlocked.contains(name);

	@:allow(objects.AchievementPopup)
	static var _popups:Array<AchievementPopup> = [];

	public static var showingPopups(get, never):Bool;
	public static function get_showingPopups():Bool
		return _popups.length > 0;

	public static function startPopup(achieve:String) {
		for (popup in _popups) {
			if (popup == null) continue;
			popup.intendedY += 150;
		}
		_popups.push(new AchievementPopup(achieve));
	}

	// Map sorting cuz haxe is physically incapable of doing that by itself
	static var _sortID:Int = 0;
	static var _originalLength:Int = -1;
	public static function createAchievement(name:String, data:Award, ?mod:String = null) {
		data.ID = _sortID;
		data.mod = mod;
		list.set(name, data);
		_sortID++;
	}

	#if MODS_ALLOWED
	public static function reloadList() {
		// remove modded achievements
		if ((_sortID + 1) > _originalLength)
			for (key => value in list)
				if (value.mod != null) list.remove(key);

		_sortID = _originalLength - 1;

		var modLoaded:String = Mods.currentModDirectory;
		Mods.currentModDirectory = null;
		loadAchievementJson(Paths.mods('data/achievements.json'));
		for (_ => mod in Mods.parseList().enabled) {
			Mods.currentModDirectory = mod;
			loadAchievementJson(Paths.mods('$mod/data/achievements.json'));
		}
		Mods.currentModDirectory = modLoaded;
	}

	inline static function loadAchievementJson(path:String, addMods:Bool = true):Array<Dynamic> {
		var retVal:Array<Dynamic> = null;
		inline function errorMessage(title:String, message:String):Void {
			utils.system.NativeUtil.showMessageBox(message, title);
			Logs.error('$title - $message');
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
						if (list.exists(key)) continue;
						createAchievement(key, achieve, Mods.currentModDirectory);
					}
				}
			} catch (e:Dynamic) errorMessage('Mod name: ' + Mods.currentModDirectory ?? "None", 'Error loading achievements.json: $e');
		}
		return retVal;
	}
	#end
}
#end