package data;

import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;
import haxe.extern.EitherType;

typedef WeekFile = {
	// JSON variables
	var songs:Array<Array<EitherType<String, Array<Int>>>>;
	var difficulties:String;
	var startUnlocked:Bool;
	var hiddenUntilUnlocked:Bool;
	var weekName:String;
	// -- STORY MENU SPECIFIC -- //
	var weekCharacters:Array<String>;
	var weekBackground:String;
	var hideStoryMode:Bool;
	var weekBefore:String;
	var storyName:String;
	// -- FREEPLAY MENU SPECIFIC -- //
	var hideFreeplay:Bool;
	var section:String;
}

class WeekData {
	public static var weeksLoaded:Map<String, WeekData> = new Map<String, WeekData>();
	public static var weeksList:Array<String> = [];

	public var folder:String = '';

	// JSON variables
	public var songs:Array<Array<EitherType<String, Array<Int>>>>;
	public var difficulties:String;
	public var startUnlocked:Bool;
	public var hiddenUntilUnlocked:Bool;
	public var weekName:String;
	// -- STORY MENU SPECIFIC -- //
	public var weekCharacters:Array<String>;
	public var weekBackground:String;
	public var hideStoryMode:Bool;
	public var weekBefore:String;
	public var storyName:String;
	// -- FREEPLAY MENU SPECIFIC -- //
	public var hideFreeplay:Bool;
	public var section:String;

	public var fileName:String;

	public static function createWeekFile():WeekFile {
		return {
			songs: [
				["Bopeebo", "daddyshark", [146, 113, 253]],
				["Fresh", "daddyshark", [146, 113, 253]],
				["Tooth", "daddyshark", [146, 113, 253]]
			],
			weekCharacters: ['bf', 'bf', 'gf'],
			weekBackground: 'stage',
			weekBefore: 'tutorial',
			storyName: 'Your New Week',
			weekName: 'Custom Week',
			startUnlocked: true,
			hiddenUntilUnlocked: false,
			hideStoryMode: false,
			hideFreeplay: false,
			difficulties: '',
			section: "mods"
		};
	}

	public function new(weekFile:WeekFile, fileName:String) {
		for (field in Reflect.fields(weekFile)) {
			if (Reflect.fields(this).contains(field)) Reflect.setProperty(this, field, Reflect.field(weekFile, field));
		}
		this.fileName = fileName;
	}

	public static function reloadWeekFiles(isStoryMode:Null<Bool> = false) {
		weeksList = [];
		weeksLoaded.clear();
		#if MODS_ALLOWED
		var directories:Array<String> = [Paths.mods(), Paths.getSharedPath()];
		var originalLength:Int = directories.length;
		for (mod in Mods.parseList().enabled) directories.push(Paths.mods('$mod/'));
		#else
		var directories:Array<String> = [Paths.getSharedPath()];
		var originalLength:Int = directories.length;
		#end

		var sexList:Array<String> = Util.readTextFiles(Paths.getSharedPath('weeks/weekList.txt'));
		for (i in 0...sexList.length) {
			for (j in 0...directories.length) {
				var fileToCheck:String = '${directories[j]}weeks/${sexList[i]}.json';
				if (!weeksLoaded.exists(sexList[i])) {
					var week:WeekFile = getWeekFile(fileToCheck);
					if (week != null) {
						var weekFile:WeekData = new WeekData(week, sexList[i]);
						#if MODS_ALLOWED if (j >= originalLength) weekFile.folder = directories[j].substring(Paths.mods().length, directories[j].length - 1); #end

						if (weekFile != null && (isStoryMode == null || (isStoryMode && !weekFile.hideStoryMode) || (!isStoryMode && !weekFile.hideFreeplay))) {
							weeksLoaded.set(sexList[i], weekFile);
							weeksList.push(sexList[i]);
						}
					}
				}
			}
		}

		#if MODS_ALLOWED
		for (i in 0...directories.length) {
			var directory:String = '${directories[i]}weeks/';
			if (FileSystem.exists(directory)) {
				for (daWeek in Util.readTextFiles(directory + 'weekList.txt')) {
					var path:String = directory + '$daWeek.json';
					if (FileSystem.exists(path)) addWeek(daWeek, path, directories[i], i, originalLength);
				}

				for (file in FileSystem.readDirectory(directory)) {
					var path:String = haxe.io.Path.join([directory, file]);
					if (!FileSystem.isDirectory(path) && file.endsWith('.json'))
						addWeek(file.substr(0, file.length - 5), path, directories[i], i, originalLength);
				}
			}
		}
		#end
	}

	static function addWeek(weekToCheck:String, path:String, directory:String, i:Int, originalLength:Int):Void {
		if (!weeksLoaded.exists(weekToCheck)) {
			var week:WeekFile = getWeekFile(path);
			if (week != null) {
				var weekFile:WeekData = new WeekData(week, weekToCheck);
				if (i >= originalLength) {
					#if MODS_ALLOWED weekFile.folder = directory.substring(Paths.mods().length, directory.length - 1); #end
				}
				if ((PlayState.isStoryMode && !weekFile.hideStoryMode) || (!PlayState.isStoryMode && !weekFile.hideFreeplay)) {
					weeksLoaded.set(weekToCheck, weekFile);
					weeksList.push(weekToCheck);
				}
			}
		}
	}

	static function getWeekFile(path:String):WeekFile {
		var rawJson:String = null;
		#if sys
		if (FileSystem.exists(path)) rawJson = File.getContent(path);
		else
		#end
		if (OpenFlAssets.exists(path)) rawJson = Assets.getText(path);

		if (rawJson != null && rawJson.length > 0) return cast tjson.TJSON.parse(rawJson);
		return null;
	}

	// To use on PlayState.hx or Highscore stuff
	public static function getWeekFileName():String return weeksList[PlayState.storyWeek];

	// Used on LoadingState, nothing really too relevant
	public static function getCurrentWeek():WeekData return weeksLoaded.get(weeksList[PlayState.storyWeek]);

	public static function setDirectoryFromWeek(?data:WeekData = null) {
		Mods.currentModDirectory = '';
		if (data != null && data.folder != null && data.folder.length > 0)
			Mods.currentModDirectory = data.folder;
	}
}