package debug.framerate;

import utils.MathUtil;

class MusicBeatInfo extends FramerateCategory {
	public function new() {
		super("Music Info");
	}

	public override function __enterFrame(t:Int) {
		if (alpha <= 0.05) return;
		_text = 'curSongPos: ${Math.floor(Conductor.songPosition * 1000) / 1000}';
		_text += '\ncurBPM: ${Conductor.bpm}';
		if (MusicBeatState.getState() != null) @:privateAccess {
			_text += '\n - ${MusicBeatState.getState().curBeat} beats';
			_text += '\n - ${MusicBeatState.getState().curStep} steps';
		}
		_text += '\nCrochet: ${MathUtil.truncateFloat(Conductor.crochet, 2)}ms/${MathUtil.truncateFloat(Conductor.stepCrochet, 2)}ms';

		this.text.text = _text;
		super.__enterFrame(t);
	}
}