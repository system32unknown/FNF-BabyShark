package backend;

import objects.Note;
import haxe.ds.Vector;

typedef SwagSong = {
	var song:String;
	var notes:Array<SwagSection>;
	var events:Array<Dynamic>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;
	var offset:Float;

	var player1:String;
	var player2:String;
	var gfVersion:String;
	var stage:String;
	var format:String;
	
	@:optional var mania:Int;
	@:optional var isOldVersion:Bool;

	@:optional var gameOverChar:String;
	@:optional var gameOverSound:String;
	@:optional var gameOverLoop:String;
	@:optional var gameOverEnd:String;

	@:optional var disableNoteRGB:Bool;
	
	@:optional var arrowSkin:String;
	@:optional var splashSkin:String;
}

typedef SwagSection = {
	var sectionNotes:Array<Dynamic>;
	var sectionBeats:Float;
	var mustHitSection:Bool;
	@:optional var altAnim:Bool;
	@:optional var gfSection:Bool;
	@:optional var bpm:Float;
	@:optional var changeBPM:Bool;
}

class Song {
	public static function convert(songJson:Dynamic) { // Convert old charts to psych_v1 format
		if (songJson.gfVersion == null) {
			songJson.gfVersion = songJson.player3;
			if (Reflect.hasField(songJson, 'player3')) Reflect.deleteField(songJson, 'player3');
		}

		if (songJson.events == null) {
			songJson.events = [];
			for (secNum in 0...songJson.notes.length) {
				var sec:SwagSection = songJson.notes[secNum];
				var i:Int = 0;
				var notes:Array<Dynamic> = sec.sectionNotes;
				var len:Int = notes.length;
				while (i < len) {
					var note:Array<Dynamic> = notes[i];
					if (note[1] < 0) {
						songJson.events.push([note[0], [[note[2], note[3], note[4]]]]);
						notes.remove(note);
						len = notes.length;
					} else i++;
				}
			}
		}

		var sectionsData:Array<SwagSection> = songJson.notes;
		if (sectionsData == null) return;

		var maniaKey:Int = EK.keys(PlayState.mania);
		for (section in sectionsData) {
			var beats:Null<Float> = cast section.sectionBeats;
			if (beats == null || Math.isNaN(beats)) {
				section.sectionBeats = 4;
				if (Reflect.hasField(section, 'lengthInSteps')) Reflect.deleteField(section, 'lengthInSteps');
			}

			for (note in section.sectionNotes) {
				var gottaHitNote:Bool = (note[1] < maniaKey) ? section.mustHitSection : !section.mustHitSection;
				note[1] = (note[1] % maniaKey) + (gottaHitNote ? 0 : maniaKey);

				if (!Std.isOfType(note[3], String))
					note[3] = Note.defaultNoteTypes[note[3]]; // compatibility with Week 7 and 0.1-0.3 psych charts
			}
		}
	}

	public static var chartPath:String;
	public static var loadedSongName:String;
	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong {
		if (folder == null) folder = jsonInput;
		PlayState.SONG = getChart(jsonInput, folder);
		loadedSongName = folder;
		chartPath = _lastPath.replace('/', '\\');
		data.StageData.loadDirectory(PlayState.SONG);
		return PlayState.SONG;
	}

	static var _lastPath:String;
	public static function getChart(jsonInput:String, ?folder:String):SwagSong {
		if (folder == null) folder = jsonInput;
		var rawData:String = null;
		
		var formattedFolder:String = Paths.formatToSongPath(folder);
		var formattedSong:String = Paths.formatToSongPath(jsonInput);
		_lastPath = Paths.json('${Paths.CHART_PATH}/$formattedFolder/$formattedSong');

		#if MODS_ALLOWED
		if (FileSystem.exists(_lastPath)) rawData = File.getContent(_lastPath);
		else
		#end
			rawData = lime.utils.Assets.getText(_lastPath);

		return rawData != null ? parseJSON(rawData, jsonInput) : null;
	}

	public static function parseJSON(rawData:String, ?nameForError:String = null, ?convertTo:String = 'psych_v1'):SwagSong {
		var isOldVer:Vector<Bool> = new Vector<Bool>(2);
		var songJson:SwagSong = cast haxe.Json.parse(rawData);
		if (Reflect.hasField(songJson, 'song')) {
			isOldVer[0] = true;
			var subSong:SwagSong = Reflect.field(songJson, 'song');
			if (subSong != null && Type.typeof(subSong) == TObject) songJson = subSong;
		} else isOldVer[0] = false;

		if (convertTo != null && convertTo.length > 0) {
			var fmt:String = songJson.format;
			if (fmt == null) {
				fmt = songJson.format = 'unknown';
				isOldVer[1] = true;
				if (isOldVer[0] && isOldVer[1]) songJson.isOldVersion = true;
			}

			switch(convertTo) {
				case 'psych_v1':
					if (!fmt.startsWith('psych_v1')) { // Convert to Psych 1.0 format
						trace('converting chart $nameForError with format $fmt to psych_v1 format...');
						songJson.format = 'psych_v1_convert';
						convert(songJson);
					}
			}
		}
		return songJson;
	}
}
