package states;

import utils.CoolUtil;

class OutdatedState extends MusicBeatState
{
	public static var leftState:Bool = false;

	public static var needVer:String = "IDFK LOL";
	public static var currChanges:String = "dk";

	var txt:FlxText;

	override function create()
	{
		super.create();

		add(new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK));

		txt = new FlxText(0, 0, FlxG.width,
			"Your Custom Build is outdated!\n
			You are on " + Main.engineVersion.version
			+ "\nwhile the most recent version is "
			+ '$needVer.'
			+ "\n\nWhat's new:\n\n"
			+ currChanges
			+ "\n& more changes and bugfixes in the full changelog
			\n\nPress Space to view the full changelog and update\nor ESCAPE to ignore this",
		32);
		txt.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER);
		txt.screenCenter();
		add(txt);
	}

	override function update(elapsed:Float)
	{
		if(!leftState) {
			if (controls.ACCEPT) {
				leftState = true;
				CoolUtil.browserLoad("https://github.com/system32unknown/FNF-BabyShark/releases/");
			} else if(controls.BACK) leftState = true;

			if(leftState) {
				FlxG.sound.play(Paths.sound('cancelMenu'));
				FlxTween.tween(txt, {alpha: 0}, 1, {
					onComplete: function (twn:FlxTween) {
						MusicBeatState.switchState(new MainMenuState());
					}
				});
			}
		}
		super.update(elapsed);
	}
}