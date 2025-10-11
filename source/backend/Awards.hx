package backend;

import flixel.util.FlxSave;
import objects.AwardPopup;

#if AWARDS_ALLOWED
class Awards {
	public static var list:Map<String, Award> = [];

	public static function init():Void {
		createAward('week1_nomiss', {name: "She Calls Me Daddy Too", description: "Beat Week 1 on Hard with no Misses."});
		createAward('week2_nomiss', {name: "No More Tricks", description: "Beat Week 2 on Hard with no Misses."});
		createAward('week3_nomiss', {name: "Call Me The Hitman", description: "Beat Week 3 on Hard with no Misses."});
		createAward('week4_nomiss', {name: "Lady Killer", description: "Beat Week 4 on Hard with no Misses."});
		createAward('week5_nomiss', {name: "Missless Christmas", description: "Beat Week 5 on Hard with no Misses."});
		createAward('week6_nomiss', {name: "Highscore!!", description: "Beat Week 6 on Hard with no Misses."});
		createAward('week7_nomiss', {name: "God Effing Damn It!", description: "Beat Week 7 on Hard with no Misses."});
		createAward('ur_bad', {name: "What a Funkin' Disaster!", description: "Complete a Song with a rating lower than 20%."});
		createAward('ur_good', {name: "Perfectionist", description: "Complete a Song with a rating of 100%."});
		createAward('toastie', {name: "Toaster Gamer", description: "Have you tried to run the game on a toaster?"});

		// dont delete this thing below
		_originalLength = _sortID + 1;
	}

	@:unreflective
	static var _unlocked:Array<String> = [];
	@:unreflective
	static var _scores:Map<String, Float> = [];

	static var _save:FlxSave;

	public static function load():Void {
		if (_originalLength < 0) init();

		if (_save == null) {
			_save = new FlxSave();
			_save.bind('awards', Util.getSavePath());
		}

		if (_save.data.list != null) {
			_unlocked.resize(0);
			_unlocked = _save.data.list.copy();
		}

		if (_save.data.scores != null) _scores = _save.data.scores.copy();
	}

	public static function save():Void {
		_save.data.list = _unlocked;
		_save.data.scores = _scores;
		_save.flush();
	}

	public static function reset(?saveToDisk:Bool = false):Void {
		_unlocked.resize(0);
		_scores = [];
		if (saveToDisk) save();
	}

	public static function isUnlocked(id:String):Bool {
		if (!exists(id)) return false;
		return _unlocked.contains(id);
	}

	public static function unlock(name:String, ?autoPopup:Bool = true):Null<String> {
		if (!list.exists(name)) {
			Sys.println('Award "$name" does not exist!');
			return null;
		}

		if (isUnlocked(name)) return null;
		trace('Completed award "$name"');
		_unlocked.push(name);

		FlxG.sound.play(Paths.sound('confirmMenu'), .5);
		if (autoPopup) startPopup(name);

		save();

		return name;
	}

	public static function getScore(id:String):Float {
		if (!_scores.exists(id)) return 0;
		return _scores[id];
	}

	public static function addScore(name:String, value:Float):Void {
		var award:Award = get(name);
		if (award == null || award.maxScore <= 0) return;

		setScore(name, _scores[name] + value);
	}

	public static function setScore(name:String, value:Float):Void {
		var award:Award = get(name);
		if (award == null || award.maxScore <= 0 || value > award.maxScore) return;

		_scores.set(name, value);
		if (value >= award.maxScore) unlock(name);
	}

	@:allow(objects.AwardPopup)
	static var _popups:Array<AwardPopup> = [];

	public static var showingPopups(get, never):Bool;
	public static function get_showingPopups():Bool return _popups.length > 0;
	public static function startPopup(id:String):Void {
		for (popup in _popups) {
			if (popup == null) continue;
			popup.intendedY += 150;
		}

		_popups.push(new AwardPopup(id));
	}

	public static function exists(name:String):Bool return list.exists(name);
	public static function get(name:String):Award return list[name];

	// Map sorting cuz haxe is physically incapable of doing that by itself
	static var _sortID:Int = 0;
	static var _originalLength:Int = -1;
	public static function createAward(name:String, data:Award, ?mod:String = null):Void {
		data.ID = _sortID;
		data.mod = mod;
		list.set(name, data);
		_sortID++;
	}

	#if MODS_ALLOWED
	public static function reloadList():Void {
		// remove modded awards
		if ((_sortID + 1) > _originalLength)
			for (key => value in list)
				if (value.mod != null) list.remove(key);

		_sortID = _originalLength - 1;

		var modLoaded:String = Mods.currentModDirectory;
		Mods.currentModDirectory = null;
		loadAwardJson(Paths.mods('data/awards.json'));
		for (_ => mod in Mods.parseList().enabled) {
			Mods.currentModDirectory = mod;
			loadAwardJson(Paths.mods('$mod/data/awards.json'));
		}
		Mods.currentModDirectory = modLoaded;
	}

	inline static function loadAwardJson(path:String, addMods:Bool = true):Array<Dynamic> {
		var retVal:Array<Dynamic> = null;
		inline function errorMessage(title:String, message:String):Void {
			utils.system.NativeUtil.showMessageBox(message, title, MSG_ERROR);
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
							errorMessage('Mod name: ' + Mods.currentModDirectory ?? "None", 'Award #${i + 1} is invalid.');
							continue;
						}

						var key:String = achieve.save;
						if (key == null || key.trim().length < 1) {
							errorMessage('Error on Award: ' + (achieve.name ?? achieve.save), 'Missing valid "save" value.');
							continue;
						}
						key = key.trim();
						if (list.exists(key)) continue;
						createAward(key, achieve, Mods.currentModDirectory);
					}
				}
			} catch (e:Dynamic) errorMessage('Mod name: ' + Mods.currentModDirectory ?? "None", 'Error loading awards.json: $e');
		}
		return retVal;
	}
	#end
}
#else
class Awards {
	public static var list:Map<String, Award> = [];
	public static function load():Void {}
	public static function save():Void {}
	public static function reset(?_):Void {}
	public static function isUnlocked(_):Bool return false;
	public static function unlock(_, ?_):Null<String> return null;
	public static function getScore(_):Float return 0;
	public static function addScore(_, _):Void {}
	public static function setScore(_, _):Void {}

	static var _popups:Array<AwardPopup> = [];

	public static var showingPopups(get, never):Bool;
	public static function get_showingPopups():Bool return _popups.length > 0;

	public static function startPopup(_) {}
	public static function exists(_):Bool return false;
	public static function get(_):Award return {};
}
#end

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