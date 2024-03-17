package backend;

import backend.Section.SwagSection;

typedef SwagSong = {
	var song:String;
	var notes:Array<SwagSection>;
	var events:Array<Dynamic>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;
	var gfVersion:String;
	var stage:String;
	
	@:optional var mania:Int;

	@:optional var gameOverChar:String;
	@:optional var gameOverSound:String;
	@:optional var gameOverLoop:String;
	@:optional var gameOverEnd:String;

	@:optional var disableNoteRGB:Bool;
	
	@:optional var arrowSkin:String;
	@:optional var splashSkin:String;
}

class Song {
	static function onLoadJson(songJson:Dynamic) { // Convert old charts to newest format
		if(songJson.gfVersion == null) {
			songJson.gfVersion = songJson.player3;
			songJson.player3 = null;
		}

		if(songJson.events == null) {
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

		if (songJson.mania == null) songJson.mania = EK.defaultMania;
	}

	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong {
		var rawJson:String = null;
		
		var formattedFolder:String = Paths.formatToSongPath(folder);
		var formattedSong:String = Paths.formatToSongPath(jsonInput);
		#if MODS_ALLOWED
		var moddyFile:String = Paths.modsJson('${Paths.CHART_PATH}/$formattedFolder/$formattedSong');
		if(FileSystem.exists(moddyFile)) rawJson = File.getContent(moddyFile).trim();
		#end

		if(rawJson == null) {
			var path:String = Paths.json('${Paths.CHART_PATH}/$formattedFolder/$formattedSong');
			#if sys
			if(FileSystem.exists(path)) rawJson = File.getContent(path);
			else
			#end
				rawJson = lime.utils.Assets.getText(path);
		}

		var songJson:Dynamic = parseJSONshit(rawJson);
		if(jsonInput != 'events') data.StageData.loadDirectory(songJson);
		onLoadJson(songJson);
		return songJson;
	}

	public static function parseJSONshit(rawJson:String):SwagSong
		return cast haxe.Json.parse(rawJson).song;
}
