package backend;

class MusicBeatSubstate extends FlxSubState {
	var curSection:Int = 0;
	var stepsToDo:Int = 0;

	var curStep:Int = 0;
	var curBeat:Int = 0;

	var curDecStep:Float = 0;
	var curDecBeat:Float = 0;

	override function update(elapsed:Float) {
		var oldStep:Int = curStep;
		updateCurStep();
		updateBeat();

		if (oldStep != curStep) {
			if (curStep > 0) stepHit();

			if (PlayState.SONG != null) {
				if (oldStep < curStep) updateSection();
				else rollbackSection();
			}
		}

		super.update(elapsed);
	}

	function updateSection():Void {
		if (stepsToDo < 1) stepsToDo = Math.round(getBeatsOnSection() * 4);
		while (curStep >= stepsToDo) {
			curSection++;
			stepsToDo += Math.round(getBeatsOnSection() * 4);
			sectionHit();
		}
	}

	function rollbackSection():Void {
		if (curStep < 0) return;

		var lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for (i in 0...PlayState.SONG.notes.length) {
			if (PlayState.SONG.notes[i] != null) {
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if (stepsToDo > curStep) break;
				curSection++;
			}
		}

		if (curSection > lastSection) sectionHit();
	}

	function updateBeat():Void {
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep / 4;
	}

	function updateCurStep():Void {
		var lastChange:Conductor.BPMChangeEvent = Conductor.getBPMChangeFromMS(Conductor.songPosition);

		var shit:Float = ((Conductor.songPosition - Settings.data.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public function stepHit():Void {
		if (curStep % 4 == 0) beatHit();
	}
	public function beatHit():Void {}
	public function sectionHit():Void {}

	function getBeatsOnSection():Int {
		var val:Null<Int> = 4;
		if (PlayState.SONG != null && PlayState.SONG.notes[curSection] != null) val = PlayState.SONG.notes[curSection].sectionBeats;
		return val ?? 4;
	}
}