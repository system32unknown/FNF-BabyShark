package debug.framerate;

import utils.MathUtil;

class MusicBeatInfo extends FramerateCategory {
	public function new() {
		super("Music Info");
	}

	public override function __enterFrame(t:Int) {
		if (alpha <= 0.05) return;
		_text = 'Current Song Position: ${Math.floor(Conductor.songPosition * 1000) / 1000}';
		_text += '\nCurrent BPM: ${Conductor.bpm}';
		if (MusicBeatState.getState() != null) @:privateAccess {
			_text += '\n - ${MusicBeatState.getState().curBeat} beats';
			_text += '\n - ${MusicBeatState.getState().curStep} steps';
		}
		_text += '\n - Crochet: ${MathUtil.truncateFloat(Conductor.crochet, 2)}MS/${MathUtil.truncateFloat(Conductor.stepCrochet, 2)}MS';

		this.text.text = _text;
		super.__enterFrame(t);
	}
}