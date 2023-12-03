package data;

import haxe.io.Path;
import haxe.Json;
import openfl.utils.Assets as OpenFlAssets;

typedef WeekFile = {
	// JSON variables
	var songs:Array<Dynamic>;
	var weekCharacters:Array<String>;
	var weekBackground:String;
	var weekBefore:String;
	var storyName:String;
	var weekName:String;
	var startUnlocked:Bool;
	var hiddenUntilUnlocked:Bool;
	var hideStoryMode:Bool;
	var hideFreeplay:Bool;
	var difficulties:String;
	var sections:Array<String>;
}

class WeekData {
	public static var weeksLoaded:Map<String, WeekData> = new Map<String, WeekData>();
	public static var weeksList:Array<String> = [];
	public var folder:String = '';
	
	// JSON variables
	public var songs:Array<Dynamic>;
	public var weekCharacters:Array<String>;
	public var weekBackground:String;
	public var weekBefore:String;
	public var storyName:String;
	public var weekName:String;
	public var startUnlocked:Bool;
	public var hiddenUntilUnlocked:Bool;
	public var hideStoryMode:Bool;
	public var hideFreeplay:Bool;
	public var difficulties:String;
	public var sections:Array<String>;

	public var fileName:String;

	public static function createWeekFile():WeekFile {
		var weekFile:WeekFile = {
			songs: [["Bopeebo", "daddyshark", [146, 113, 253]], ["Fresh", "daddyshark", [146, 113, 253]], ["Tooth", "daddyshark", [146, 113, 253]]],
			weekCharacters: ['', 'bf', 'gf'],
			weekBackground: 'stage',
			weekBefore: 'tutorial',
			storyName: 'Your New Week',
			weekName: 'Custom Week',
			startUnlocked: true,
			hiddenUntilUnlocked: false,
			hideStoryMode: false,
			hideFreeplay: false,
			difficulties: '',
			sections: ["mods"]
		};
		return weekFile;
	}

	// HELP: Is there any way to convert a WeekFile to WeekData without having to put all variables there manually? I'm kind of a noob in haxe lmao
	public function new(weekFile:WeekFile, fileName:String) {
		for (field in Reflect.fields(weekFile))
			try {Reflect.setProperty(this, field, Reflect.getProperty(weekFile, field));}
			catch(e) Logs.trace('INVAILD WEEKDATA ($fileName): $e', ERROR);
		this.fileName = fileName;
	}

	public static function reloadWeekFiles(isStoryMode:Null<Bool> = false) {
		weeksList = [];
		weeksLoaded.clear();
		#if MODS_ALLOWED
		var directories:Array<String> = [Paths.mods(), Paths.getPreloadPath()];
		var originalLength:Int = directories.length;
		for (mod in Mods.parseList().enabled)
			directories.push(Paths.mods('$mod/'));
		#else
		var directories:Array<String> = [Paths.getPreloadPath()];
		var originalLength:Int = directories.length;
		#end

		for (asset in OpenFlAssets.getLibrary("weeks").list(null)) {
			for (j in 0...directories.length) {
				if (asset.endsWith(".json")) {
					var weekName = asset.replace('${directories[j]}weeks/', "").replace(".json", "");
					var fileToCheck:String = (directories[j].contains("assets") ? Paths.getLibraryPath('$weekName.json', 'weeks') : '${directories[j]}weeks/$weekName.json');
					if (!weeksLoaded.exists(weekName)) {
						var week:WeekFile = getWeekFile(fileToCheck);
						if (week != null) {
							var weekFile:WeekData = new WeekData(week, weekName);

							#if MODS_ALLOWED
							if(j >= originalLength)
								weekFile.folder = directories[j].substring(Paths.mods().length, directories[j].length - 1);
							#end

							if (weekFile != null && (isStoryMode == null || (isStoryMode && !weekFile.hideStoryMode) || (!isStoryMode && !weekFile.hideFreeplay))) {
								weeksLoaded.set(weekName, weekFile);
								weeksList.push(weekName);
							}
						}
					}
				}
			}
		}

		#if MODS_ALLOWED
		for (i in 0...directories.length) {
			var directory:String = '${directories[i]}weeks/';
			if(FileSystem.exists(directory)) {
				var listOfWeeks:Array<String> = CoolUtil.coolTextFile(directory + 'weekList.txt');
				for (daWeek in listOfWeeks) {
					var path:String = directory + '$daWeek.json';
					if(FileSystem.exists(path))
						addWeek(daWeek, path, directories[i], i, originalLength);
				}

				for (file in FileSystem.readDirectory(directory)) {
					var path = Path.join([directory, file]);
					if (!FileSystem.isDirectory(path) && file.endsWith('.json'))
						addWeek(file.substr(0, file.length - 5), path, directories[i], i, originalLength);
				}
			}
		}
		#end
	}

	static function addWeek(weekToCheck:String, path:String, directory:String, i:Int, originalLength:Int) {
		if(!weeksLoaded.exists(weekToCheck)) {
			var week:WeekFile = getWeekFile(path);
			if(week != null) {
				var weekFile:WeekData = new WeekData(week, weekToCheck);
				if (i >= originalLength) {
					#if MODS_ALLOWED
					weekFile.folder = directory.substring(Paths.mods().length, directory.length - 1);
					#end
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
		#if MODS_ALLOWED
		if(FileSystem.exists(path)) rawJson = File.getContent(path);
		#else
		if(OpenFlAssets.exists(path)) rawJson = Assets.getText(path);
		#end

		if(rawJson != null && rawJson.length > 0)
			return cast Json.parse(rawJson);
		return null;
	}

	//To use on PlayState.hx or Highscore stuff
	public static function getWeekFileName():String return weeksList[PlayState.storyWeek];

	//Used on LoadingState, nothing really too relevant
	public static function getCurrentWeek():WeekData return weeksLoaded.get(weeksList[PlayState.storyWeek]);

	public static function setDirectoryFromWeek(?data:WeekData = null) {
		Mods.currentModDirectory = '';
		if(data != null && data.folder != null && data.folder.length > 0)
			Mods.currentModDirectory = data.folder;
	}
}