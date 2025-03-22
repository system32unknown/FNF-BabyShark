package states;

import flixel.effects.FlxFlicker;

class FlashingState extends flixel.FlxState {
	public static var leftState:Bool = false;

	var isYes:Bool = true;
	var texts:FlxTypedSpriteGroup<FlxText>;
	var bg:FlxSprite;

	override function create() {
		super.create();

		add(bg = new FlxSprite().makeSolid(FlxG.width, FlxG.height, FlxColor.BLACK));

		texts = new FlxTypedSpriteGroup<FlxText>();
		texts.alpha = 0.0;
		add(texts);

		var warnText:FlxText = new FlxText(0, 0, FlxG.width,
			"Hey, watch out!\n
			This Mod contains some flashing lights!\n
			Do you wish to disable them?");
		warnText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		warnText.gameCenter(Y);
		texts.add(warnText);

		final keys:Array<String> = ["Yes", "No"];
		for (i in 0...keys.length) {
			final button:FlxText = new FlxText(0, 0, FlxG.width, keys[i], 32);
			button.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
			button.y = (warnText.y + warnText.height) + 24;
			button.x += (128 * i) - 80;
			texts.add(button);
		}

		FlxTween.tween(texts, {alpha: 1.0}, .5, {onComplete: (_) -> updateItems()});
	}

	override function update(elapsed:Float) {
		if (leftState) {
			super.update(elapsed);
			return;
		}
		var back:Bool = Controls.justPressed('back');
		if (Controls.justPressed('ui_left') || Controls.justPressed('ui_right')) {
			FlxG.sound.play(Paths.sound("scrollMenu"), .7);
			isYes = !isYes;
			updateItems();
		}
		if (Controls.justPressed('accept') || back) {
			leftState = true;
			MusicBeatState.skipNextTransIn = MusicBeatState.skipNextTransOut = true;
			if (!back) {
				Settings.data.flashing = !isYes;
				Settings.save();
				FlxG.sound.play(Paths.sound('confirmMenu'));
				final button:FlxText = texts.members[isYes ? 1 : 2];
				FlxFlicker.flicker(button, 1, 0.1, false, true, (_:FlxFlicker) -> FlxTimer.wait(.5, () -> FlxTween.tween(texts, {alpha: 0}, .2, {onComplete: (_) -> FlxG.switchState(() -> new TitleState())})));
			} else {
				FlxG.sound.play(Paths.sound('cancelMenu'));
				FlxTween.tween(texts, {alpha: 0}, 1, {onComplete: (_) -> FlxG.switchState(() -> new TitleState())});
			}
		}
	}

	function updateItems() {
		// it's clunky but it works.
		texts.members[1].alpha = isYes ? 1. : .6;
		texts.members[2].alpha = isYes ? .6 : 1.;
	}
}