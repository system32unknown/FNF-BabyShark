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
	static function set_bpm(newBPM:Float):Float {
		crochet = calculateCrochet(newBPM);
		stepCrochet = crochet / 4;
		return bpm = newBPM;
	}

	public static var crochet:Float = calculateCrochet(bpm); // beats in milliseconds
	public static var stepCrochet:Float = crochet / 4; // steps in milliseconds
	public static var songPosition:Float = 0;
	public static var offset:Float = 0;

	public static var safeZoneOffset:Float = 0; // is calculated in create(), is safeFrames in milliseconds

	public static var bpmChanges:Array<BPMChangeEvent> = [];

	inline public static function calculateCrochet(bpm:Float):Float {
		return (60 / bpm) * 1000;
	}

	public static function getBPMChangeFromMS(time:Float):BPMChangeEvent {
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: bpm,
			stepCrochet: stepCrochet
		}

		if (bpmChanges.length == 0) return lastChange;

		for (i in 0...bpmChanges.length) {
			final change:BPMChangeEvent = bpmChanges[i];
			if (time >= change.songTime) lastChange = change;
			else break;
		}

		return lastChange;
	}

	public static function setBPMChanges(song:SwagSong) {
		bpmChanges = [];

		var curBPM:Float = song.bpm;
		var curSteps:Int = 0;
		var curTime:Float = 0.0;

		for (i => section in song.notes) {
			if (section.changeBPM && section.bpm != curBPM) {
				curBPM = section.bpm;
				bpmChanges.push({
					stepTime: curSteps,
					songTime: curTime,
					bpm: curBPM,
					stepCrochet: calculateCrochet(curBPM) / 4
				});
			}
			var sectionBeats:Int = Math.round(getSectionBeats(section) * 4);
			curSteps += sectionBeats;
			curTime += (calculateCrochet(curBPM) / 4) * sectionBeats;
		}
	}

	inline static function getSectionBeats(section:SwagSection):Int return section?.sectionBeats ?? 4;
}