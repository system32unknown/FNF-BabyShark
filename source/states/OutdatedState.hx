package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import utils.CoolUtil;

class OutdatedState extends MusicBeatState
{
	public static var leftState:Bool = false;

	public static var needVer:String = "IDFK LOL";
	public static var currChanges:String = "dk";

	override function create()
	{
		super.create();

		var kadeLogo:FlxSprite = new FlxSprite(FlxG.width, 0).loadGraphic(Paths.image('KadeEngineLogo'));
		kadeLogo.scale.set(.3, .3);
		kadeLogo.x -= kadeLogo.frameHeight;
		kadeLogo.y -= 180;
		kadeLogo.alpha = 0.8;
		kadeLogo.antialiasing = ClientPrefs.getPref('globalAntialiasing');
		add(kadeLogo);

		var txt:FlxText = new FlxText(0, 0, FlxG.width,
			"Your Version is outdated!\nYou are on "
			+ Main.engineVersion.version
			+ "\nwhile the most recent version is "
			+ needVer
			+ "."
			+ "\n\nWhat's new:\n\n"
			+ currChanges
			+ "\n& more changes and bugfixes in the full changelog"
			+ "\n\nPress Space to view the full changelog and update\nor ESCAPE to ignore this",
		32);
		txt.setFormat("Comic Sans MS Bold", 32, FlxColor.fromRGB(200, 200, 200), CENTER);
        txt.setBorderStyle(OUTLINE, FlxColor.BLUE, 3);
		txt.screenCenter();
		add(txt);

		FlxTween.angle(kadeLogo, kadeLogo.angle, -10, 2, {ease: FlxEase.quartInOut});
		new FlxTimer().start(2, function(tmr:FlxTimer) {
			if (kadeLogo.angle == -10)
				FlxTween.angle(kadeLogo, kadeLogo.angle, 10, 2, {ease: FlxEase.quartInOut});
			else FlxTween.angle(kadeLogo, kadeLogo.angle, -10, 2, {ease: FlxEase.quartInOut});
		}, 0);
	}

	override function update(elapsed:Float)
	{
		if (controls.ACCEPT) {
			CoolUtil.browserLoad("https://github.com/system32unknown/FNF-BabyShark/release/latest");
		} else if (controls.ACCEPT) {
			leftState = true;
			MusicBeatState.switchState(new MainMenuState());
		}

		if (controls.BACK) {
			leftState = true;
			MusicBeatState.switchState(new MainMenuState());
		}
		super.update(elapsed);
	}
}