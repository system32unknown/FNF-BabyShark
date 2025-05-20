package backend;

import objects.Note;

import moonchart.formats.OsuMania;
import moonchart.formats.StepMania;
import moonchart.formats.StepManiaShark;
import moonchart.formats.BasicFormat.BasicNoteType;

// just to make sure chart parsing doesn't kill itself
typedef JsonChart = {
	var notes:Array<Section>;
	var ?events:Array<Dynamic>;
	var speed:Float;
}

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

	@:optional var gameOverChar:String;
	@:optional var gameOverSound:String;
	@:optional var gameOverLoop:String;
	@:optional var gameOverEnd:String;

	@:optional var disableNoteRGB:Bool;

	@:optional var arrowSkin:String;
	@:optional var splashSkin:String;
}

typedef Section = {
	var sectionNotes:Array<Dynamic>;
	var sectionBeats:Int;
	var mustHitSection:Bool;
	@:optional var altAnim:Bool;
	@:optional var gfSection:Bool;
	@:optional var bpm:Float;
	@:optional var changeBPM:Bool;
}

class FNFChart extends moonchart.formats.fnf.legacy.FNFLegacy {
 	public function new() {
    	super();

    	this.indexedTypes = false;
    	this.bakedOffset = false;
    	this.offsetHolds = false;

    	noteTypeResolver.register("Hurt Note", BasicNoteType.MINE);
  	}
}

class NewSong {
	public static function createDummyFile():Chart {
		return {
			song: 'Test',
			notes: [{
				sectionNotes: [],
				mustHitSection: false,
				gfSection: false,
				altAnim: false
			}],
			events: [],
			bpm: 150,
			needsVoices: true,
			speed: 1.0,
			offset: 0,
			mania: 3,

			player1: 'bf',
			player2: 'dad',
			gfVersion: 'gf',
			stage: 'stage',
			format: 'psych_v1'
		}
	}

	public static function loadFromPath(path:String):Chart {
		var file:Chart = createDummyFile();

		path = Paths.get(path);
		if (!FileSystem.exists(path)) return file;

		var rawChart:JsonChart = switch haxe.io.Path.extension(path) {
			case 'json':
				cast Json.parse(File.getContent(path)).song;

			case 'sm':
				var fnf:FNFChart = new FNFChart();
				cast fnf.fromFormat(new StepMania().fromFile(path)).data.song;

			case 'ssc':
				var fnf:FNFChart = new FNFChart();
				cast fnf.fromFormat(new StepManiaShark().fromFile(path)).data.song;

			case 'osu':
				var fnf:FNFChart = new FNFChart();
				cast fnf.fromFormat(new OsuMania().fromFile(path)).data.song;

			default: null;
		}

		for (property in Reflect.fields(rawChart)) {
			if (!Reflect.hasField(file, property)) continue;
			Reflect.setField(file, property, Reflect.field(rawChart, property));
		}

		return file;
	}

	public static function load(song:String, diff:String):Chart {
		var file:Chart = loadFromPath('songs/$song/${getFile(song, diff)}');
		file.meta = Meta.load(song);

		return file;
	}

	public static function parse(chart:Chart):Array<NoteData> {
		final notes:Array<NoteData> = [];
		if (chart == null) return notes;

		for (section in chart.notes) {
			for (note in section.sectionNotes) {
				notes.push({
					time: Math.max(0, note[0]),
					lane: Std.int(note[1] % 4),
					length: note[2],
					type: (note[3] is String ? note[3] : Note.defaultTypes[note[3]]) ?? '',
					altAnim: section.altAnim,
					player: note[1] > 3 != section.mustHitSection ? 1 : 0,
				});
			}
		}

		notes.sort((a, b) -> Std.int(a.time - b.time));
		return notes;
	}

	static var formats:Array<String> = ['json', 'sm', 'osu'];
	public static function getFile(song:String, diff:String) {
		diff = Difficulty.format(diff);
		var file:String = '$diff.${formats[0]}';
		var path:String = Paths.get('songs/$song');

		if (!FileSystem.exists(path)) return file;

		var files:Array<String> = FileSystem.readDirectory(path);
		for (format in formats) {
			if (files.contains('$diff.$format')) { // shouldnt this be endsWith? or use haxe.io.Path.withoutDirectory
				file = '$diff.$format';
				break;
			}
		}

		return file;
	}
}