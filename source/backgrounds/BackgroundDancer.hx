package backgrounds;

import flixel.FlxSprite;
import utils.ClientPrefs;
import utils.CoolUtil;

class BackgroundDancer extends FlxSprite
{
	public function new(x:Float, y:Float)
	{
		super(x, y);

		frames = Paths.getSparrowAtlas("limo/limoDancer");
		animation.addByIndices('danceLeft', 'bg dancer sketch PINK', CoolUtil.numberArray(14), "", 24, false);
		animation.addByIndices('danceRight', 'bg dancer sketch PINK', CoolUtil.numberArray(30, 15), "", 24, false);
		animation.play('danceLeft');
		antialiasing = ClientPrefs.getPref('globalAntialiasing');
	}

	var danceDir:Bool = false;
	public function dance():Void
	{
		danceDir = !danceDir;

		if (danceDir) animation.play('danceRight', true);
		else animation.play('danceLeft', true);
	}
}
