package utils;

import sys.FileSystem;
import sys.io.File;
import tjson.TJSON as Json;
import haxe.io.Path;

typedef ModsList = {
	enabled:Array<String>,
	disabled:Array<String>,
	all:Array<String>
};

class Mods
{
	public static var currentModDirectory:String = '';

	public static var ignoreModFolders:Array<String> = [
		'characters',
		'custom_events',
		'custom_notetypes',
		'custom_gamechangers',
		'data',
		'songs',
		'music',
		'sounds',
		'shaders',
		'videos',
		'images',
		'stages',
		'weeks',
		'fonts',
		'scripts',
		'achievements',
		'options'
	];

	static var globalMods:Array<String> = [];

	inline public static function getGlobalMods()
		return globalMods;

	inline public static function pushGlobalMods() { // prob a better way to do this but idc
		globalMods = [];
		for(mod in parseList().enabled) {
			var pack:Dynamic = getPack(mod);
			if(pack != null && pack.runsGlobally) globalMods.push(mod);
		}
		return globalMods;
	}

	inline public static function isValidModDir(dir:String):Bool
		return FileSystem.isDirectory(Path.join([Paths.mods(), dir])) && !ignoreModFolders.contains(dir.toLowerCase());

	inline public static function getActiveModsDir(inclMainFol:Bool = false):Array<String> {
		var finalList:Array<String> = [];
		if (inclMainFol) finalList.push('');
		
		var path:String = 'modsList.txt';
		if(FileSystem.exists(path)) {
			var genList:Array<String> = getModDirectories();
			var list:Array<String> = CoolUtil.coolTextFile(path);
			for (i in list) {
				var dat = i.split("|");
				if (dat[1] == "1" && genList.contains(dat[0])) finalList.push(dat[0]);
			}
		}
		return finalList;
	}
	
	inline public static function getActiveModDirectories(lowercase:Bool = false):Array<String> {
		var list:Array<String> = [];
		final path:String = 'modsList.txt';

		var remains:Array<String> = getModDirectories(true);

		if (remains.length <= 0 || !FileSystem.exists(path)) return list;
		var leMods:Array<String> = CoolUtil.coolTextFile(path);

		for (i in 0...leMods.length) {
			if (remains.length <= 0) break;
			if (leMods.length > 1 && leMods[0].length > 0) {
				var modSplit:Array<String> = leMods[i].split('|');
				var modLower:String = modSplit[0].toLowerCase();

				if (remains.contains(modLower) && modSplit[1] == '1') {
					remains.remove(modLower);
					list.push(lowercase ? modLower : modSplit[0]);
				}
			}
		}

		remains = null;
		return list;
	}

	inline public static function getModDirectories(lowercase:Bool = false):Array<String> {
		var list:Array<String> = [];
		var modsFolder:String = Paths.mods();

		if (!FileSystem.exists(modsFolder)) return list;

		for (folder in FileSystem.readDirectory(modsFolder)) {
			var path:String = Path.join([modsFolder, folder]);
			var lower:String = folder.toLowerCase();

			if (FileSystem.isDirectory(path) && !ignoreModFolders.contains(lower) && !list.contains(folder))
				list.push(lowercase ? lower : folder);
		}

		return list;
	}
	public static function getPack(?folder:String = null):Dynamic {
		if(folder == null) folder = currentModDirectory;

		var path = Paths.mods(folder + '/pack.json');
		if(FileSystem.exists(path)) {
			try {
				var rawJson:String = File.getContent(path);
				if(rawJson != null && rawJson.length > 0) return Json.parse(rawJson);
			} catch(e:Dynamic) trace(e);
		}
		return null;
	}

	public static var updatedOnState:Bool = false;
	inline public static function parseList():ModsList {
		if(!updatedOnState) updateModList();
		var list:ModsList = {enabled: [], disabled: [], all: []};

		try {
			for (mod in CoolUtil.coolTextFile('modsList.txt')) {
				var dat = mod.split("|");
				list.all.push(dat[0]);
				if (dat[1] == "1")
					list.enabled.push(dat[0]);
				else list.disabled.push(dat[0]);
			}
		} catch(e) trace(e);
		return list;
	}

	static function updateModList() {
		// Find all that are already ordered
		var list:Array<Array<Dynamic>> = [];
		var added:Array<String> = [];
		try {
			for (mod in CoolUtil.coolTextFile('modsList.txt')) {
				var dat:Array<String> = mod.split("|");
				var folder:String = dat[0];
				if(FileSystem.exists(Paths.mods(folder)) && FileSystem.isDirectory(Paths.mods(folder)) && !added.contains(folder)) {
					added.push(folder);
					list.push([folder, (dat[1] == "1")]);
				}
			}
		} catch(e) trace(e);

		// Scan for folders that aren't on modsList.txt yet
		for (folder in getModDirectories()) {
			if(FileSystem.exists(Paths.mods(folder)) && FileSystem.isDirectory(Paths.mods(folder)) &&
			!ignoreModFolders.contains(folder.toLowerCase()) && !added.contains(folder)) {
				added.push(folder);
				list.push([folder, true]); //i like it false by default. -bb //Well, i like it True! -Shadow Mario (2022)
				//Shadow Mario (2023): What the fuck was bb thinking
			}
		}

		// Now save file
		var fileStr:String = '';
		for (values in list) {
			if(fileStr.length > 0) fileStr += '\n';
			fileStr += values[0] + '|' + (values[1] ? '1' : '0');
		}

		File.saveContent('modsList.txt', fileStr);
		updatedOnState = true;
	}

	public static function loadTopMod() {
		currentModDirectory = '';

		#if MODS_ALLOWED
		var list:Array<String> = parseList().enabled;
		if(list != null && list[0] != null)
			currentModDirectory = list[0];
		#end
	}
}