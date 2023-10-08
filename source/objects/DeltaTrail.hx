package objects;

import flixel.addons.effects.FlxTrail;
import flixel.system.FlxAssets;
import flixel.math.FlxPoint;

/**
 * FlxTrail but it uses delta time.
 * @author Rozebud :]
*/
class DeltaTrail extends FlxTrail {
	var _timer:Float = 0;
	var timerMax:Float;
	
	/**
	 * Creates a new DeltaTrail effect for a specific FlxSprite.
	 *
	 * @param	Target		The FlxSprite the trail is attached to.
	 * @param  	Graphic		The image to use for the trailsprites. Optional, uses the sprite's graphic if null.
	 * @param	Length		The maximum amount of trailsprites to create.
	 * @param	Delay		Amount of time in between each trail update 
	 * @param	Alpha		The alpha value for the very first trailsprite.
	 * @param	Diff		The amount subtracted from the trailsprite's alpha every update. If null, it will be auto calculated to end at 0 based on Length.
	 */
	public function new(target:FlxSprite, ?Graphic:FlxGraphicAsset, length:Int = 10, delay:Float = 3 / 60, alpha:Float = .5, diff:Float = null):Void {
		if(diff == null) diff = alpha / length;
		super(target, graphic, length, 0, alpha, diff);
		timerMax = delay;
	}

	override public function update(elapsed:Float):Void {
		// Count the frames
		_timer += elapsed;

		// Update the trail in case the intervall and there actually is one.
		if (_timer >= timerMax && _trailLength >= 1) {
			_timer = 0;

			// Push the current position into the positons array and drop one.
			var spritePosition:FlxPoint = (_recentPositions.length == _trailLength) ? _recentPositions.pop() : FlxPoint.get();
			spritePosition.set(target.x - target.offset.x, target.y - target.offset.y);
			_recentPositions.unshift(spritePosition);

			// Also do the same thing for the Sprites angle if rotationsEnabled
			if (rotationsEnabled)
				cacheValue(_recentAngles, target.angle);

			// Again the same thing for Sprites scales if scalesEnabled
			if (scalesEnabled) {
				var spriteScale:FlxPoint = (_recentScales.length == _trailLength) ? _recentScales.pop() : FlxPoint.get();
				spriteScale.set(target.scale.x, target.scale.y);
				_recentScales.unshift(spriteScale);
			}

			// Again the same thing for Sprites frames if framesEnabled
			if (framesEnabled && _graphic == null) {
				cacheValue(_recentFrames, target.animation.frameIndex);
				cacheValue(_recentFlipX, target.flipX);
				cacheValue(_recentFlipY, target.flipY);
				cacheValue(_recentAnimations, target.animation.curAnim);
			}

			// Now we need to update the all the Trailsprites' values
			var trailSprite:FlxSprite;

			for (i in 0..._recentPositions.length) {
				trailSprite = members[i];
                trailSprite.setPosition(_recentPositions[i].x, _recentPositions[i].y);

				// And the angle...
				if (rotationsEnabled) {
					trailSprite.angle = _recentAngles[i];
                    trailSprite.origin.copyFrom(_spriteOrigin);
				}

				// the scale...
				if (scalesEnabled)
                    trailSprite.scale.copyFrom(_recentScales[i]);

				// and frame...
				if (framesEnabled && _graphic == null) {
					trailSprite.animation.frameIndex = _recentFrames[i];
					trailSprite.flipX = _recentFlipX[i];
					trailSprite.flipY = _recentFlipY[i];

					trailSprite.animation.curAnim = _recentAnimations[i];
				}

				// Is the trailsprite even visible?
				trailSprite.exists = true;
			}
		}
	}
}