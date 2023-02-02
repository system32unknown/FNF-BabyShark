package game;

import game.Section.SwagSection;
import utils.ClientPrefs;
import data.StageData;
import game.Note;
import haxe.Json;

#if sys
import sys.io.File;
import sys.FileSystem;
#else
import lime.utils.Assets;
#end

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

	var mania:Null<Int>;
	var screwYou:String;

	var arrowSkin:String;
	var splashSkin:String;
}

class Song {
	public var song:String;
	public var notes:Array<SwagSection>;
	public var bpm:Float;

	public function new(song, notes, bpm) {
		this.song = song;
		this.notes = notes;
		this.bpm = bpm;
	}

	public static function getSongPath(folder:String, song:String):String {
		return Paths.formatToSongPath(folder) + '/' + Paths.formatToSongPath(song);
	}

	private static function onLoadJson(songJson:Dynamic) // Convert old charts to newest format
	{
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

		if (songJson.mania == null) {
            songJson.mania = Note.defaultMania;
        }
	}

	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		var rawJson = null;
		
		var formattedPath:String = getSongPath((folder == null ? jsonInput : folder), jsonInput);
		#if MODS_ALLOWED
		var moddyFile:String = Paths.modsJson(formattedPath);
		if (FileSystem.exists(moddyFile)) {
			rawJson = File.getContent(moddyFile).trim();
		}
		#end

		var jsonPath = Paths.json(formattedPath);
		if (rawJson == null && Paths.fileExists(jsonPath, TEXT, true, true)) {
			#if sys
			rawJson = File.getContent(jsonPath).trim();
			#else
			rawJson = Assets.getText(jsonPath).trim();
			#end
		}

		if (rawJson == null) return null;

		while (!rawJson.endsWith("}")) {
			rawJson = rawJson.substr(0, rawJson.length - 1);
		}
		
		var songJson:Dynamic = parseJSONshit(rawJson);
		if(jsonInput != 'events') StageData.loadDirectory(songJson);
		onLoadJson(songJson);
		return songJson;
	}

	public static function parseJSONshit(rawJson:String):SwagSong
		return cast Json.parse(rawJson).song;
}
