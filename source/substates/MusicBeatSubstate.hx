package substates;

import utils.Controls;
import utils.ClientPrefs;
import utils.PlayerSettings;
import game.Conductor;
import flixel.FlxSubState;

class MusicBeatSubstate extends FlxSubState
{
	private var curStep:Int = 0;
	private var controls(get, never):Controls;

	inline function get_controls():Controls
		return PlayerSettings.player.controls;

	public function new()
	{
		super();
	}

	override function update(elapsed:Float)
	{
		var oldStep:Int = curStep;

		updateCurStep();

		if (oldStep != curStep && curStep > 0)
			stepHit();

		super.update(elapsed);
	}

	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit = ((Conductor.songPosition - ClientPrefs.getPref('noteOffset')) - lastChange.songTime) / lastChange.stepCrochet;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		//do literally nothing dumbass
	}
}
