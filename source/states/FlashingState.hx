package states;

import flixel.effects.FlxFlicker;
import flixel.addons.transition.FlxTransitionableState;

class FlashingState extends MusicBeatState {
	public static var leftState:Bool = false;

	var warnText:FlxText;
	override function create() {
		super.create();

		warnText = new FlxText(0, 0, 0,
			"Welcome to Alter Engine!\n
			This Mod contains some flashing lights!\n
			Press ENTER to disable them now or go to Options Menu.\n
			Press ESCAPE to ignore this message.\n
			You've been warned!", 32);
		warnText.setFormat(Paths.font('babyshark.ttf'), 32, FlxColor.WHITE, CENTER);
		warnText.scrollFactor.set();
		warnText.screenCenter();
		add(warnText);
	}

	override function update(elapsed:Float) {
		if(!leftState) {
			var back:Bool = controls.BACK;
			if (controls.ACCEPT || back) {
				leftState = true;
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
				if(!back) {
					ClientPrefs.prefs.set('flashing', false);
					ClientPrefs.saveSettings();
					FlxG.sound.play(Paths.sound('confirmMenu'));
					FlxFlicker.flicker(warnText, 1, .1, false, true, (flk:FlxFlicker) -> new FlxTimer().start(.5, (tmr:FlxTimer) -> MusicBeatState.switchState(new TitleState())));
				} else {
					FlxG.sound.play(Paths.sound('cancelMenu'));
					FlxTween.tween(warnText, {alpha: 0}, 1, {onComplete: (twn:FlxTween) -> MusicBeatState.switchState(new TitleState())});
				}
			}
		}
		super.update(elapsed);
	}
}