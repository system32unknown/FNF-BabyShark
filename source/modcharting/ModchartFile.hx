package modcharting;

import haxe.Json;
import lime.utils.Assets;

typedef ModchartJson = {
	var modifiers:Array<Array<Dynamic>>;
	var events:Array<Array<Dynamic>>;
	var playfields:Int;
}

class ModchartFile {
	// used for indexing
	public static final MOD_NAME = 0; // the modifier name
	public static final MOD_CLASS = 1; // the class/custom mod it uses
	public static final MOD_TYPE = 2; // the type, which changes if its for the player, opponent, a specific lane or all
	public static final MOD_PF = 3; // the playfield that mod uses
	public static final MOD_LANE = 4; // the lane the mod uses

	public static final EVENT_TYPE = 0; // event type (set or ease)
	public static final EVENT_DATA = 1; // event data
	public static final EVENT_REPEAT = 2; // event repeat data

	public static final EVENT_TIME = 0; // event time (in beats)
	public static final EVENT_SETDATA = 1; // event data (for sets)
	public static final EVENT_EASETIME = 1; // event ease time
	public static final EVENT_EASE = 2; // event ease
	public static final EVENT_EASEDATA = 3; // event data (for eases)

	public static final EVENT_REPEATBOOL = 0; // if event should repeat
	public static final EVENT_REPEATCOUNT = 1; // how many times it repeats
	public static final EVENT_REPEATBEATGAP = 2; // how many beats in between each repeat

	public var data:ModchartJson = null;

	var renderer:PlayfieldRenderer;

	public var scriptListen:Bool = false;
    #if hscript
    public var customModifiers:Map<String, Dynamic> = new Map<String, Dynamic>();
    #end
	public var hasDifficultyModchart:Bool = false; // so it loads false as default!

	public function new(renderer:PlayfieldRenderer) {
		data = loadFromJson(PlayState.SONG.song.toLowerCase(), Difficulty.getString().toLowerCase() == null ? Difficulty.defaultList[PlayState.storyDifficulty] : Difficulty.getString().toLowerCase());
		this.renderer = renderer;
		renderer.modchart = this;
		loadPlayfields();
		loadModifiers();
		loadEvents();
	}

	public function loadFromJson(folder:String, difficulty:String):ModchartJson { // load da shit
		var rawJson = null;
		var filePath = null;

		var folderShit:String = "";

		var moddyFile:String = Paths.json(Paths.formatToSongPath(folder));
		var moddyFile2:String = Paths.json(Paths.formatToSongPath(folder));

		#if MODS_ALLOWED
		var moddyFileMods:String = Paths.modsJson(Paths.formatToSongPath(folder) + '/modchart-' + difficulty.toLowerCase());
		var moddyFileMods2:String = Paths.modsJson(Paths.formatToSongPath(folder) + '/modchart');
		#end

		try {
			#if sys
			#if MODS_ALLOWED
			if (FileSystem.exists(moddyFileMods) && difficulty.toLowerCase() != null) hasDifficultyModchart = true;
			if (FileSystem.exists(moddyFileMods2) && !FileSystem.exists(moddyFileMods)) hasDifficultyModchart = false;
			else if (FileSystem.exists(moddyFileMods2) && difficulty.toLowerCase() == null && !FileSystem.exists(moddyFileMods)) hasDifficultyModchart = false;
			#end

			if (FileSystem.exists(moddyFile) && difficulty.toLowerCase() != null) hasDifficultyModchart = true;
			if (FileSystem.exists(moddyFile) && !FileSystem.exists(moddyFile)) hasDifficultyModchart = false;
			else if (FileSystem.exists(moddyFile2) && difficulty.toLowerCase() == null && !FileSystem.exists(moddyFile)) hasDifficultyModchart = false;

			#if MODS_ALLOWED
			if (hasDifficultyModchart) {
				rawJson = File.getContent(moddyFileMods).trim();
				folderShit = moddyFileMods.replace('modchart-' + difficulty.toLowerCase() + '.json', "customMods/");
				trace('$difficulty Modchart Found In Mods! loading modchart-${difficulty.toLowerCase()}.json');
			} else {
				rawJson = File.getContent(moddyFileMods2).trim();
				folderShit = moddyFileMods2.replace('modchart.json', "customMods/");
				trace('$difficulty Modchart Has Not Been Found In Mods! loading modchart.json');
			}
			#end

			if (hasDifficultyModchart) {
				rawJson = File.getContent(moddyFile).trim();
				folderShit = moddyFile.replace('modchart-' + difficulty.toLowerCase() + '.json', "customMods/");
				trace('$difficulty Modchart Found! loading modchart-${difficulty.toLowerCase()}.json');
			} else {
				rawJson = File.getContent(moddyFile2).trim();
				folderShit = moddyFile2.replace('modchart.json', "customMods/");
				trace('$difficulty Modchart Has Not Been Found! loading modchart.json');
			}
			#else
			#if MODS_ALLOWED
			if (Assets.exists(moddyFileMods) && difficulty.toLowerCase() != null) hasDifficultyModchart = true;
			if (Assets.exists(moddyFileMods2) && !Assets.exists(moddyFileMods)) hasDifficultyModchart = false;
			else if (Assets.exists(moddyFileMods2) && difficulty.toLowerCase() == null && !Assets.exists(moddyFileMods)) hasDifficultyModchart = false;
			#end

			if (Assets.exists(moddyFile) && difficulty.toLowerCase() != null) hasDifficultyModchart = true;
			if (Assets.exists(moddyFile) && !Assets.exists(moddyFile)) hasDifficultyModchart = false;
			else if (Assets.exists(moddyFile2) && difficulty.toLowerCase() == null && !Assets.exists(moddyFile)) hasDifficultyModchart = false;

			#if MODS_ALLOWED
			if (hasDifficultyModchart) {
				rawJson = File.getContent(moddyFileMods).trim();
				folderShit = moddyFileMods.replace('modchart-' + difficulty.toLowerCase() + '.json', "customMods/");
				trace('${difficulty} Modchart Found In Mods! loading modchart-${difficulty.toLowerCase()}.json');
			} else {
				rawJson = File.getContent(moddyFileMods2).trim();
				folderShit = moddyFileMods2.replace('modchart.json', "customMods/");
				trace('${difficulty} Modchart Has Not Been Found In Mods! loading modchart.json');
			}
			#end

			if (hasDifficultyModchart) {
				rawJson = File.getContent(moddyFile).trim();
				folderShit = moddyFile.replace('modchart-' + difficulty.toLowerCase() + '.json', "customMods/");
				trace('${difficulty} Modchart Found! loading modchart-${difficulty.toLowerCase()}.json');
			} else {
				rawJson = File.getContent(moddyFile2).trim();
				folderShit = moddyFile2.replace('modchart.json', "customMods/");
				trace('${difficulty} Modchart Has Not Been Found! loading modchart.json');
			}
			#end
		} catch (e:Dynamic) Logs.trace("Modchart ERROR: " + e, ERROR);

		if (rawJson == null) {
			try {
				#if MODS_ALLOWED
				if (hasDifficultyModchart) {
					filePath = Paths.modsJson('${Paths.CHART_PATH}/$folder/modchart-${difficulty.toLowerCase()}');
					folderShit = filePath.replace('modchart-' + difficulty.toLowerCase() + '.json', "customMods/");
					trace('${difficulty} Modchart FolderShit Found In Mods! loading modchart-${difficulty.toLowerCase()}.json');
				} else {
					filePath = Paths.modsJson('${Paths.CHART_PATH}/$folder/modchart');
					folderShit = filePath.replace('modchart.json', "customMods/");
					trace('${difficulty} Modchart Has No FolderShit Found In Mods! loading modchart.json');
				}
				#end

				if (hasDifficultyModchart) {
					filePath = Paths.json('${Paths.CHART_PATH}/$folder/modchart-' + difficulty.toLowerCase());
					folderShit = filePath.replace('modchart-' + difficulty.toLowerCase() + '.json', "customMods/");
					trace('${difficulty} Modchart FolderShit Found! loading modchart-${difficulty.toLowerCase()}.json');
				} else {
					filePath = Paths.json('${Paths.CHART_PATH}/$folder/modchart');
					folderShit = filePath.replace('modchart.json', "customMods/");
					trace('${difficulty} Modchart Has No FolderShit Found! loading modchart.json');
				}
			} catch (e:Dynamic) Logs.trace("Modchart ERROR: " + e, ERROR);

			#if sys
			if (FileSystem.exists(filePath)) rawJson = File.getContent(filePath).trim();
			else
			#end // should become else if i think???
			if (Assets.exists(filePath)) rawJson = Assets.getText(filePath).trim();
		}

		var json:ModchartJson = null;
		if (rawJson != null) {
			for (i in 0...difficulty.length) json = cast Json.parse(rawJson);
			trace('loaded json: ' + folderShit);

            #if (hscript && sys)
            if (FileSystem.isDirectory(folderShit)) {
                for (file in FileSystem.readDirectory(folderShit)) {
                    if(file.endsWith('.hx')) { //custom mods!!!!
                        var scriptStr:String = File.getContent(folderShit + file);
                        var scriptInit:Dynamic = null;
                        scriptInit = new psychlua.HScript(null, scriptStr);
                        customModifiers.set(file.replace(".hx", ""), scriptInit);
                        trace('loaded custom mod: ' + file);
                    }
                }
            }
            #end
		} else json = {modifiers: [], events: [], playfields: 1};
		return json;
	}

	public function loadEmpty():Void {
		data.modifiers = [];
		data.events = [];
		data.playfields = 1;
	}

	public function loadModifiers():Void {
		if (data == null || renderer == null) return;
		renderer.modifierTable.clear();
		for (i in data.modifiers) {
			ModchartFuncs.startMod(i[MOD_NAME], i[MOD_CLASS], i[MOD_TYPE], Std.parseInt(i[MOD_PF]), renderer.instance);
			if (i[MOD_LANE] != null) ModchartFuncs.setModTargetLane(i[MOD_NAME], i[MOD_LANE], renderer.instance);
		}
		renderer.modifierTable.reconstructTable();
	}

	public function loadPlayfields():Void {
		if (data == null || renderer == null) return;

		renderer.playfields = [];
		for (i in 0...data.playfields) renderer.addNewPlayfield(0, 0, 0, 1);
	}

	public function loadEvents():Void {
		if (data == null || renderer == null) return;
		renderer.eventManager.clearEvents();
		for (i in data.events) {
			if (i[EVENT_REPEAT] == null) // add repeat data if it doesnt exist
				i[EVENT_REPEAT] = [false, 1, 0];

			if (i[EVENT_REPEAT][EVENT_REPEATBOOL]) {
				for (j in 0...(Std.int(i[EVENT_REPEAT][EVENT_REPEATCOUNT]) + 1)) {
					addEvent(i, (j * i[EVENT_REPEAT][EVENT_REPEATBEATGAP]));
				}
			} else addEvent(i);
		}
	}

	function addEvent(i:Array<Dynamic>, ?beatOffset:Float = 0):Void {
		switch (i[EVENT_TYPE]) {
			case "ease": ModchartFuncs.ease(Std.parseFloat(i[EVENT_DATA][EVENT_TIME]) + beatOffset, Std.parseFloat(i[EVENT_DATA][EVENT_EASETIME]), i[EVENT_DATA][EVENT_EASE], i[EVENT_DATA][EVENT_EASEDATA], renderer.instance);
			case "set": ModchartFuncs.set(Std.parseFloat(i[EVENT_DATA][EVENT_TIME]) + beatOffset, i[EVENT_DATA][EVENT_SETDATA], renderer.instance);
		}
	}

	public function createDataFromRenderer():Void { // a way to convert script modcharts into json modcharts
		if (renderer == null) return;

		data.playfields = renderer.playfields.length;
		scriptListen = true;
	}
}
