package states;

import flixel.effects.FlxFlicker;
import flixel.addons.transition.FlxTransitionableState;

class FlashingState extends MusicBeatState {
	public static var leftState:Bool = false;

	var warnText:FlxText;
	var pressText:FlxText;
	var preeSine:Float = 0;
	override function create() {
		super.create();

		warnText = new FlxText(0, 0, 0,'Welcome to Alter Engine! (v${Main.engineVer.version})\nThis Mod contains some flashing lights and swearing. (Or Maybe?)\nMost contents are unfinished.\nYou\'ve been warned!', 32);
		warnText.setFormat(Paths.font('babyshark.ttf'), 32, FlxColor.WHITE, CENTER);
		warnText.scrollFactor.set();
		warnText.screenCenter();
		add(warnText);

		pressText = new FlxText(0, warnText.y + warnText.height, 0, "Press ENTER to disable them now or go to Options Menu.\nPress ESCAPE to ignore this message.", 16);
		pressText.setFormat(Paths.font('vcr.ttf'), 16, FlxColor.WHITE, CENTER);
		pressText.scrollFactor.set();
		pressText.screenCenter(X);
		add(pressText);
	}

	override function update(elapsed:Float) {
		if(!leftState) {
			var back:Bool = controls.BACK;
			if (controls.ACCEPT || back) {
				leftState = true;
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
				if(!back) {
					ClientPrefs.data.flashing = false;
					ClientPrefs.saveSettings();
					FlxG.sound.play(Paths.sound('confirmMenu'));
					FlxFlicker.flicker(warnText, 1, .1, false, true, (flk:FlxFlicker) -> FlxTimer.wait(.5, () -> FlxG.switchState(() -> new TitleState())));
				} else {
					FlxG.sound.play(Paths.sound('cancelMenu'));
					FlxTween.tween(warnText, {alpha: 0}, 1, {onComplete: (twn:FlxTween) -> FlxG.switchState(() -> new TitleState())});
				}
				FlxTween.tween(pressText, {alpha: 0}, 1);
			}

			if(pressText != null) {
				preeSine += 180 * elapsed;
				pressText.alpha = 1 - Math.sin((Math.PI * preeSine) / 180);
			}
		}
		super.update(elapsed);
	}
}