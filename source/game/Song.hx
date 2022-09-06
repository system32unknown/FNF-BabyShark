package game;

import game.Section.SwagSection;
import data.StageData;
import game.Note;
import haxe.Json;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

using StringTools;

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
	var validScore:Bool;

	var mania:Int;

	var arrowSkin:String;
	var splashSkin:String;
}

class Song {
	public var song:String;
	public var notes:Array<SwagSection>;
	public var events:Array<Dynamic>;
	public var bpm:Float;
	public var needsVoices:Bool = true;
	public var speed:Float = 1;

	public var arrowSkin:String;
	public var splashSkin:String;

	public var stage:String;

	public var player1:String = 'bf';
	public var player2:String = 'dad';
	public var gfVersion:String = 'gf';

	public var keyCount:Null<Int> = 4;
	public var playerKeyCount:Null<Int> = 4;

	public function new(song, notes, bpm)
	{
		this.song = song;
		this.notes = notes;
		this.bpm = bpm;
	}

	private static function onLoadJson(songJson:Dynamic) // Convert old charts to newest format
	{
		if(songJson.gfVersion == null) {
			songJson.gfVersion = songJson.player3;
			songJson.player3 = null;
		}

		if(Std.string(songJson.keyCount) == "null")
			songJson.keyCount = 4;

		if(Std.string(songJson.playerKeyCount) == "null")
			songJson.playerKeyCount = songJson.keyCount;

		if(Std.string(songJson.mania) != "null") {
			switch(songJson.mania) {
				case 0: songJson.keyCount = 4;
				case 1: songJson.keyCount = 6;
				case 2: songJson.keyCount = 7;
				case 3: songJson.keyCount = 9;
			}
		}

		songJson.mania = null;

		if(songJson.keyCount > Note.maxMania)
			songJson.keyCount = Note.maxMania;

		if(songJson.events == null)
		{
			songJson.events = [];
			for (secNum in 0...songJson.notes.length)
			{
				var sec:SwagSection = songJson.notes[secNum];

				var i:Int = 0;
				var notes:Array<Dynamic> = sec.sectionNotes;
				var len:Int = notes.length;
				while(i < len) {
					var note:Array<Dynamic> = notes[i];
					if(note[1] < 0) {
						songJson.events.push([note[0], [[note[2], note[3], note[4]]]]);
						notes.remove(note);
						len = notes.length;
					}
					else i++;
				}
			}
		}
	}

	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		var rawJson = null;
		
		var formattedFolder:String = Paths.formatToSongPath(folder);
		var formattedSong:String = Paths.formatToSongPath(jsonInput);
		#if MODS_ALLOWED
		var moddyFile:String = Paths.modsJson(formattedFolder + '/' + formattedSong);
		if(FileSystem.exists(moddyFile)) {
			rawJson = File.getContent(moddyFile).trim();
		}
		#end

		if(rawJson == null) {
			#if sys
			rawJson = File.getContent(Paths.json(formattedFolder + '/' + formattedSong)).trim();
			#else
			rawJson = Assets.getText(Paths.json(formattedFolder + '/' + formattedSong)).trim();
			#end
		}

		while (!rawJson.endsWith("}"))
		{
			rawJson = rawJson.substr(0, rawJson.length - 1);
			// LOL GOING THROUGH THE BULLSHIT TO CLEAN IDK WHATS STRANGE
		}
		
		var songJson:Dynamic = parseJSONshit(rawJson);
		if(jsonInput != 'events') StageData.loadDirectory(songJson);
		onLoadJson(songJson);
		return songJson;
	}

	public static function parseJSONshit(rawJson:String):SwagSong
	{
		var swagShit:SwagSong = cast Json.parse(rawJson).song;
		swagShit.validScore = true;

		return swagShit;
	}
}
