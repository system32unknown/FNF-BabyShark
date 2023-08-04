package backend;

import objects.AchievementPopup;
import haxe.Exception;
class Achievements {
	public static var variables:Map<String, Float> = [];
	public static var achievementsStuff:Array<Dynamic> = [
		//Name -- Description -- Achievement save tag -- is hidden while locked -- variable name -- max variable number -- max number of decimals you want it to display
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
	public static var achievementsUnlocked:Array<String> = [];
	static var _firstLoad:Bool = true;

	public static function load():Void {
		if(!_firstLoad) return;

		if(FlxG.save.data != null) {
			if(FlxG.save.data.achievementsUnlocked != null)
				achievementsUnlocked = FlxG.save.data.achievementsUnlocked;

			var savedMap:Map<String, Float> = cast FlxG.save.data.achievementsVariables;
			if(savedMap != null) {
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

	public static function getVar(name:String):Null<Float> {
		if(!variables.exists(name)) {
			FlxG.log.error('Invalid Achievement variable name: $name');
			throw new Exception('Invalid Achievement variable name: $name');
			return null;
		}
		return variables.get(name);
	}
	public static function setVar(name:String, value:Float):Null<Float> {
		if(!variables.exists(name)) {
			FlxG.log.error('Invalid Achievement variable name: $name');
			throw new Exception('Invalid Achievement variable name: $name');
			return null;
		}
		variables.set(name, value);
		return value;
	}
	public static function addToVar(name:String, add:Float = 1):Null<Float> {
		if(!variables.exists(name)) {
			FlxG.log.error('Invalid Achievement variable name: $name');
			throw new Exception('Invalid Achievement variable name: $name');
			return null;
		}
		var val = variables.get(name) + add;
		variables.set(name, val);
		return val;
	}

	static var _lastUnlock:Int = -999;
	public static function unlockAchievement(name:String, autoStartPopup:Bool = true):String {
		if(Achievements.getAchievementIndex(name) < 0) {
			FlxG.log.error('Achievement "$name" does not exists!');
			throw new Exception('Achievement "$name" does not exists!');
			return null;
		}

		if(Achievements.isAchievementUnlocked(name)) return null;

		trace('Completed achievement "$name"');
		achievementsUnlocked.push(name);

		// earrape prevention
		var time:Int = openfl.Lib.getTimer();
		if(Math.abs(time - _lastUnlock) >= 100) { //If last unlocked happened in less than 100 ms (0.1s) ago, then don't play sound
			FlxG.sound.play(Paths.sound('confirmMenu'), 0.5);
			_lastUnlock = time;
		}

		Achievements.save();
		FlxG.save.flush();

		if(autoStartPopup) startPopup(name);
		return name;
	}

	public static function isAchievementUnlocked(name:String)
		return achievementsUnlocked.contains(name);

	public static function getAchievementIndex(name:String) {
		for (i in 0...achievementsStuff.length)
			if (achievementsStuff[i][2] == name)
				return i;
		return -1;
	}

	#if ACHIEVEMENTS_ALLOWED
	@:allow(objects.AchievementPopup)
	static var _popups:Array<AchievementPopup> = [];

	public static var showingPopups(get, never):Bool;
	public static function get_showingPopups()
		return _popups.length > 0;

	public static function startPopup(achieve:String, endFunc:Void->Void = null) {
		for (popup in _popups) {
			if(popup == null) continue;
			popup.intendedY += 150;
		}
		_popups.push(new AchievementPopup(achieve, endFunc));
	}
	#end
}