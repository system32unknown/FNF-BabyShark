package backend;

typedef ModsList = {
	enabled:Array<String>,
	disabled:Array<String>,
	all:Array<String>
};

class Mods {
	public static var currentModDirectory:String = '';
	public static final ignoreModFolders:Array<String> = [
		'characters',
		'custom_events',
		'custom_notetypes',
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
		'achievements'
	];

	static var globalMods:Array<String> = [];

	inline public static function getGlobalMods():Array<String>
		return globalMods;

	inline public static function pushGlobalMods():Array<String> { // prob a better way to do this but idc
		globalMods = [];
		for (mod in parseList().enabled) {
			var pack:Dynamic = getPack(mod);
			if (pack != null && pack.runsGlobally) globalMods.push(mod);
		}
		return globalMods;
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
			var path:String = haxe.io.Path.join([modsFolder, folder]);
			var lower:String = folder.toLowerCase();

			if (FileSystem.isDirectory(path) && !ignoreModFolders.contains(lower) && !list.contains(folder))
				list.push(lowercase ? lower : folder);
		}

		return list;
	}

	inline public static function mergeAllTextsNamed(path:String, ?defaultDirectory:String = null, allowDuplicates:Bool = false):Array<String> {
		if (defaultDirectory == null) defaultDirectory = Paths.getSharedPath();
		defaultDirectory = defaultDirectory.trim();
		if (!defaultDirectory.endsWith('/')) defaultDirectory += '/';
		if (!defaultDirectory.startsWith('assets/')) defaultDirectory = 'assets/$defaultDirectory';

		var mergedList:Array<String> = [];
		var paths:Array<String> = directoriesWithFile(defaultDirectory, path);

		var defaultPath:String = defaultDirectory + path;
		if (paths.contains(defaultPath)) {
			paths.remove(defaultPath);
			paths.insert(0, defaultPath);
		}

		for (file in paths) {
			for (value in CoolUtil.coolTextFile(file))
				if ((allowDuplicates || !mergedList.contains(value)) && value.length > 0)
					mergedList.push(value);
		}
		return mergedList;
	}

	inline public static function directoriesWithFile(path:String, fileToFind:String, mods:Bool = true):Array<String> {
		var foldersToCheck:Array<String> = [];
		if (FileSystem.exists(path + fileToFind))
			foldersToCheck.push(path + fileToFind);

		if (Paths.currentLevel != null && Paths.currentLevel != path) {
			var pth:String = Paths.getFolderPath(fileToFind, Paths.currentLevel);
			if (FileSystem.exists(pth)) foldersToCheck.push(pth);
		}
		
		#if MODS_ALLOWED
		if (mods) {
			// Global mods first
			for (mod in getGlobalMods()) {
				var folder:String = Paths.mods('$mod/$fileToFind');
				if (FileSystem.exists(folder) && !foldersToCheck.contains(folder)) foldersToCheck.push(folder);
			}

			var folder:String = Paths.mods(fileToFind); // Then "PsychEngine/mods/" main folder
			if (FileSystem.exists(folder) && !foldersToCheck.contains(folder)) foldersToCheck.push(Paths.mods(fileToFind));

			if (currentModDirectory != null && currentModDirectory.length > 0) {
				var folder:String = Paths.mods('$currentModDirectory/$fileToFind'); // And lastly, the loaded mod's folder
				if (FileSystem.exists(folder) && !foldersToCheck.contains(folder)) foldersToCheck.push(folder);
			}
		}
		#end
		return foldersToCheck;
	}

	public static function getPack(?folder:String = null):Dynamic {
		#if MODS_ALLOWED
		if (folder == null) folder = currentModDirectory;

		var path:String = Paths.mods('$folder/pack.json');
		if (FileSystem.exists(path)) {
			try {
				var rawJson:String = #if sys File.getContent #else openfl.utils.Assets.getText #end(path);
				if (rawJson != null && rawJson.length > 0) return tjson.TJSON.parse(rawJson);
			} catch (e:Dynamic) Logs.trace('ERROR: $e', ERROR);
		}
		#end
		return null;
	}

	public static var updatedOnState:Bool = false;
	inline public static function parseList():ModsList {
		if (!updatedOnState) updateModList();
		var list:ModsList = {enabled: [], disabled: [], all: []};
		try {
			for (mod in CoolUtil.coolTextFile('modsList.txt')) {
				if (mod.trim().length < 1) continue;

				var dat:Array<String> = mod.split("|");
				list.all.push(dat[0]);
				if (dat[1] == "1") list.enabled.push(dat[0]);
				else list.disabled.push(dat[0]);
			}
		} catch (e) Logs.trace('ERROR: $e', ERROR);
		return list;
	}

	static function updateModList() {
		#if MODS_ALLOWED
		// Find all that are already ordered
		var list:Array<Array<Dynamic>> = [];
		var added:Array<String> = [];
		try {
			for (mod in CoolUtil.coolTextFile('modsList.txt')) {
				var dat:Array<String> = mod.split("|");
				var folder:String = dat[0];
				if (folder.trim().length > 0 && FileSystem.exists(Paths.mods(folder)) && FileSystem.isDirectory(Paths.mods(folder)) && !added.contains(folder)) {
					added.push(folder);
					list.push([folder, (dat[1] == "1")]);
				}
			}
		} catch (e) Logs.trace('ERROR: $e', ERROR);

		// Scan for folders that aren't on modsList.txt yet
		for (folder in getModDirectories()) {
			if (folder.trim().length > 0 && FileSystem.exists(Paths.mods(folder)) && FileSystem.isDirectory(Paths.mods(folder)) && !ignoreModFolders.contains(folder.toLowerCase()) && !added.contains(folder)) {
				added.push(folder);
				list.push([folder, true]);
			}
		}

		// Now save file
		var fileStr:String = '';
		for (values in list) {
			if (fileStr.length > 0) fileStr += '\n';
			fileStr += values[0] + '|' + (values[1] ? '1' : '0');
		}

		File.saveContent('modsList.txt', fileStr);
		updatedOnState = true;
		#end
	}

	public static function loadTopMod() {
		currentModDirectory = '';

		#if MODS_ALLOWED
		var list:Array<String> = parseList().enabled;
		if (list != null && list[0] != null) currentModDirectory = list[0];
		#end
	}
}