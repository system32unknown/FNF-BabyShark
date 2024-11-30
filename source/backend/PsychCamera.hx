package backend;

// PsychCamera handles followLerp based on elapsed
// and stops camera from snapping at higher framerates

class PsychCamera extends FlxCamera {
	override public function update(elapsed:Float):Void {
		// follow the target, if there is one
		if (target != null) {
			updateFollow();
			updateLerp(elapsed);
		}

		updateScroll();
		updateFlash(elapsed);
		updateFade(elapsed);

		flashSprite.filters = filtersEnabled ? filters : null;

		updateFlashSpritePosition();
		updateShake(elapsed);
	}

	override function updateLerp(elapsed:Float):Void {
		var mult:Float = 1 - Math.exp(-elapsed * followLerp / (1 / 60));
		scroll.add((_scrollTarget.x - scroll.x) * mult, (_scrollTarget.y - scroll.y) * mult);
	}
}