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

	public static var safeZoneOffset:Float = (ClientPrefs.getPref('safeFrames') / 60) * 1000; // is calculated in create(), is safeFrames in milliseconds

	public static var bpmChangeMap:Array<BPMChangeEvent> = [];

	public function new() {}

	inline public static function calculateCrochet(bpm:Float):Float
		return (60 / bpm) * 1000;

	public static function judgeNote(arr:Array<Rating>, diff:Float = 0):Rating {
		var data:Array<Rating> = arr;
		for(i in 0...data.length - 1) //skips last window (Shit)
			if (diff <= data[i].hitWindow) return data[i];
		return data[data.length - 1];
	}

	public static function getCrotchetAtTime(time:Float) {
		var lastChange = getBPMFromSeconds(time);
		return lastChange.stepCrochet * 4;
	}

	public static function getBPMFromSeconds(time:Float) {
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: bpm,
			stepCrochet: stepCrochet
		}
		for (i in 0...Conductor.bpmChangeMap.length) {
			if (time >= Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		return lastChange;
	}

	public static function getBPMFromStep(step:Float) {
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: bpm,
			stepCrochet: stepCrochet
		}
		for (i in 0...Conductor.bpmChangeMap.length) {
			if (Conductor.bpmChangeMap[i].stepTime <= step)
				lastChange = Conductor.bpmChangeMap[i];
		}

		return lastChange;
	}

	public static function beatToSeconds(beat:Float):Float {
		var step = beat * 4;
		var lastChange = getBPMFromStep(step);
		return lastChange.songTime + ((step - lastChange.stepTime) / (lastChange.bpm / 60) / 4) * 1000; // TODO: make less shit and take BPM into account PROPERLY
	}

	public static function getStep(time:Float) {
		var lastChange = getBPMFromSeconds(time);
		return lastChange.stepTime + (time - lastChange.songTime) / lastChange.stepCrochet;
	}

	public static function getStepRounded(time:Float) {
		var lastChange = getBPMFromSeconds(time);
		return lastChange.stepTime + Math.floor(time - lastChange.songTime) / lastChange.stepCrochet;
	}

	public static function getBeat(time:Float) {
		return getStep(time) / 4;
	}

	public static function getBeatRounded(time:Float):Int {
		return Math.floor(getStepRounded(time) / 4);
	}

	public static function mapBPMChanges(song:SwagSong) {
		bpmChangeMap = [];

		var curBPM:Float = song.bpm;
		var totalPos:Float = 0, totalSteps = 0;

		var deltaSteps, v;
		for (i in 0...song.notes.length) {
			v = song.notes[i];

			if (v.changeBPM && v.bpm != curBPM) {
				curBPM = v.bpm;
				bpmChangeMap.push({
					stepTime: totalSteps,
					songTime: totalPos,
					bpm: curBPM,
					stepCrochet: calculateCrochet(curBPM) / 4
				});
			}

			totalSteps += (deltaSteps = Math.round(getSectionBeats(song, i) * 4));
			totalPos += (calculateCrochet(curBPM) / 4) * deltaSteps;
		}
	}

	static function getSectionBeats(song:SwagSong, section:Int) {
		var val:Null<Float> = null;
		if(song.notes[section] != null) val = song.notes[section].sectionBeats;
		return val != null ? val : 4;
	}

	public static function set_bpm(newBPM:Float):Float {
		crochet = calculateCrochet(newBPM);
		stepCrochet = crochet / 4;
		return bpm = newBPM;
	}
}