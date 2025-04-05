package objects;

/**
 * FlxTrail but it uses delta time.
 * @author Rozebud :]
 */
class DeltaTrail extends flixel.addons.effects.FlxTrail {
	var _timer:Float = 0;
	var timerMax:Float;

	/**
	 * Creates a new DeltaTrail effect for a specific FlxSprite.
	 *
	 * @param	Target		The FlxSprite the trail is attached to.
	 * @param	Graphic		The image to use for the trailsprites. Optional, uses the sprite's graphic if null.
	 * @param	Length		The maximum amount of trailsprites to create.
	 * @param	Delay		Amount of time in between each trail update 
	 * @param	Alpha		The alpha value for the very first trailsprite.
	 * @param	Diff		The amount subtracted from the trailsprite's alpha every update. If null, it will be auto calculated to end at 0 based on Length.
	 */
	public function new(target:FlxSprite, ?graphic:flixel.system.FlxAssets.FlxGraphicAsset, length:Int = 10, delay:Float = 3 / 60, alpha:Float = .5, diff:Float = null):Void {
		if (diff == null) diff = alpha / length;
		super(target, graphic, length, 0, alpha, diff);
		timerMax = delay;
	}

	/**
	 * An offset applied to the target position whenever a new frame is saved.
	 */
	public final frameOffset:FlxPoint = FlxPoint.get();

	override function destroy():Void {
		super.destroy();
		frameOffset.put();
	}

	override public function update(elapsed:Float):Void {
		_timer += elapsed; // Count the frames

		// Update the trail in case the intervall and there actually is one.
		if (_timer >= timerMax && _trailLength >= 1) {
			_timer = 0;
			addTrailFrame();
			redrawTrailSprites(); // Now we need to update the all the Trailsprites' values
		}
	}

	override function addTrailFrame():Void {
		super.addTrailFrame();

		if (target is Character) {
			var chr:Character = cast target;
			@:privateAccess
			frameOffset.set((chr.positionArray[0] - chr.cameraPosition[0]) * chr.scale.x, (chr.positionArray[1] - chr.cameraPosition[1]) * chr.scale.y);
			_recentPositions[0]?.subtract(frameOffset.x, frameOffset.y);
		}
	}
}