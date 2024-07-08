package debug.framerate;

import utils.MathUtil;

class MusicBeatInfo extends FramerateCategory {
	public function new() {
		super("Music Info");
	}

	public override function __enterFrame(t:Int) {
		if (alpha <= 0.05) return;
		_text = 'curBPM: ${Conductor.bpm}';
		if (MusicBeatState.getState() != null) @:privateAccess {
			_text += '\n- ${MusicBeatState.getState().curBeat} beats';
			_text += '\n- ${MusicBeatState.getState().curStep} steps';
			_text += '\n- ${MusicBeatState.getState().curSection} sections';
		}
		_text += '\nCrochet: ${MathUtil.truncateFloat(Conductor.crochet, 2)}ms/${MathUtil.truncateFloat(Conductor.stepCrochet, 2)}ms';

		this.text.text = _text;
		super.__enterFrame(t);
	}
}