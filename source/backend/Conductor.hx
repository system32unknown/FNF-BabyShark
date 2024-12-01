package backend;

import backend.Song;

typedef BPMChangeEvent = {
	var stepTime:Int;
	var songTime:Float;
	var bpm:Float;
	@:optional var stepCrochet:Float;
}

class Conductor {
	public static var bpm(default, set):Float = 100;
	public static var crochet:Float = calculateCrochet(bpm); // beats in milliseconds
	public static var stepCrochet:Float = crochet / 4; // steps in milliseconds
	public static var songPosition:Float = 0;
	public static var offset:Float = 0;

	public static var safeZoneOffset:Float = 0; // is calculated in create(), is safeFrames in milliseconds

	public static var bpmChangeMap:Array<BPMChangeEvent> = [];

	public static function judgeNote(arr:Array<Rating>, diff:Float = 0, bot:Bool = false):Rating {
		var data:Array<Rating> = arr;
		if (bot) return data[0]; // botplay returns first rating

		for(i in 0...data.length - 1) if (diff <= data[i].hitWindow) return data[i]; //skips last window (Shit)
		return data[data.length - 1];
	}

	public static function getBPMFromSeconds(time:Float):BPMChangeEvent {
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: bpm,
			stepCrochet: stepCrochet
		}
		for (i in 0...bpmChangeMap.length) {
			if (time >= bpmChangeMap[i].songTime)
				lastChange = bpmChangeMap[i];
		}

		return lastChange;
	}

	public static function getBPMFromStep(step:Float):BPMChangeEvent {
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: bpm,
			stepCrochet: stepCrochet
		}
		for (i in 0...bpmChangeMap.length) {
			if (bpmChangeMap[i].stepTime <= step)
				lastChange = bpmChangeMap[i];
		}

		return lastChange;
	}

	public static function mapBPMChanges(song:SwagSong) {
		bpmChangeMap = [];

		var curBPM:Float = song.bpm;
		var totalPos:Float = 0, totalSteps:Int = 0;

		for (i in 0...song.notes.length) {
			if(song.notes[i].changeBPM && song.notes[i].bpm != curBPM) {
				curBPM = song.notes[i].bpm;
				bpmChangeMap.push({
					stepTime: totalSteps,
					songTime: totalPos,
					bpm: curBPM,
					stepCrochet: calculateCrochet(curBPM) / 4
				});
			}
			var deltaSteps:Int = Math.round(getSectionBeats(song, i) * 4);
			totalSteps += deltaSteps;
			totalPos += (calculateCrochet(curBPM) / 4) * deltaSteps;
		}
	}

	static function getSectionBeats(song:SwagSong, section:Int):Float {
		var val:Null<Float> = null;
		if(song.notes[section] != null) val = song.notes[section].sectionBeats;
		return val ?? 4;
	}

	inline public static function calculateCrochet(bpm:Float):Float {
		return (60 / bpm) * 1000;
	}

	static function set_bpm(newBPM:Float):Float {
		crochet = calculateCrochet(newBPM);
		stepCrochet = crochet / 4;
		return bpm = newBPM;
	}
}