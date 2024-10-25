package states;

import flixel.effects.FlxFlicker;

class FlashingState extends flixel.FlxState {
	var warnText:FlxText;
	public static var pressedKey:Bool = false;
	override function create() {
		super.create();

		warnText = new FlxText(0, 0, FlxG.width,
			"Hey, watch out!\n
			This Mod contains some flashing lights!\n
			Press ENTER to disable them now or go to Options Menu.\n
			Press ESCAPE to ignore this message.\n
			You've been warned!",
			32);
		warnText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		warnText.screenCenter(Y);
		add(warnText);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		if (pressedKey) return;
		var backJustPressed:Bool = Controls.justPressed('back');
		if (backJustPressed || Controls.justPressed('accept')) {
			pressedKey = true;
			if (backJustPressed) {
				FlxG.sound.play(Paths.sound('cancelMenu'));
				FlxTween.tween(warnText, {alpha: 0}, 1, {onComplete: (_:FlxTween) -> FlxG.switchState(() -> new TitleState())});
				return;
			}
			ClientPrefs.data.flashing = false;
			ClientPrefs.save();
			FlxG.sound.play(Paths.sound('confirmMenu'));
			FlxFlicker.flicker(warnText, 1, 0.1, false, true, (_:FlxFlicker) -> FlxG.switchState(() -> new TitleState()));	
		}
	}
}