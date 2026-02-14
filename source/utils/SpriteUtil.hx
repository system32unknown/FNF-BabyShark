package utils;

import flixel.graphics.FlxGraphic;

class SpriteUtil {
	/**
	 * Returns the most present color in a FlxSprite.
	 * @param sprite The sprite to analyze
	 * @param saturated Whether to consider saturation when determining the dominant color
	 * @return The most present color in the sprite
	 */
	public static function getMostPresentColor(sprite:FlxSprite, saturated:Bool):FlxColor {
		if (sprite == null || sprite.pixels == null || sprite.frameWidth <= 0 || sprite.frameHeight <= 0) {
			return FlxColor.TRANSPARENT;
		}

		var weights:Map<Int, Float> = new Map<Int, Float>();

		var bestKey:Int = 0;
		var bestWeight:Float = -1;

		for (x in 0...sprite.frameWidth) {
			for (y in 0... sprite.frameHeight) {
				var argb:Int = sprite.pixels.getPixel32(x, y);

				var a:Int = (argb >>> 24) & 0xFF;
				if (a == 0) continue; // skip fully transparent pixels

				// Force alpha to 0xFF, preserve RGB
				var key:Int = 0xFF000000 | (argb & 0x00FFFFFF);

				var w:Null<Float> = weights.get(key);
				if (w == null) w = 0;

				var alphaW:Float = a / 255;

				if (saturated) {
					// Only compute HSL if needed
					var c:FlxColor = FlxColor.fromInt(key);

					var l:Float = c.lightness;
					w += alphaW * 0.33 + 0.67 * (c.saturation * (2 * ((l > .5) ? (1 - l) : l)));
				} else w += alphaW;

				weights.set(key, w);

				if (w > bestWeight) {
					bestWeight = w;
					bestKey = key;
				}
			}
		}

		return FlxColor.fromInt(bestKey);
	}

	/**
	 * Determines the dominant color in a sprite by counting occurrences.
	 * @param sprite The sprite to analyze
	 * @return The most frequent color with full opacity
	 */
	public static function dominantColor(sprite:FlxSprite):FlxColor {
		var countByColor:Map<Int, Int> = [];
		for (col in 0...sprite.frameWidth) {
			for (row in 0...sprite.frameHeight) {
				var colorOfThisPixel:FlxColor = sprite.pixels.getPixel32(col, row);
				if (colorOfThisPixel.alphaFloat < .05) continue;

				colorOfThisPixel = FlxColor.fromRGB(colorOfThisPixel.red, colorOfThisPixel.green, colorOfThisPixel.blue, 255);
				var count:Int = countByColor.exists(colorOfThisPixel) ? countByColor[colorOfThisPixel] : 0;
				countByColor[colorOfThisPixel] = count + 1;
			}
		}

		var maxCount:Int = 0;
		var maxKey:FlxColor = 0; // after the loop this will store the max color
		countByColor[FlxColor.BLACK] = 0;
		for (key => count in countByColor) {
			if (count <= maxCount) continue;
			maxCount = count;
			maxKey = key;
		}
		countByColor.clear();
		return FlxColor.fromInt(maxKey);
	}

	/**
	 * Resets an FlxSprite.
	 * 
	 * @param  spr  Sprite to reset
	 * @param  x	New X position
	 * @param  y	New Y position
	 */
	public static function resetSprite(spr:FlxSprite, x:Float, y:Float):Void {
		spr.reset(x, y);
		spr.alpha = 1;
		spr.visible = spr.active = true;
		spr.acceleration.set();
		spr.velocity.set();
		spr.drag.set();
		spr.antialiasing = FlxSprite.defaultAntialiasing;
		FlxTween.cancelTweensOf(spr);
	}

	public static function makeOutlinedGraphic(width:Int, height:Int, Color:Int, thickness:Int, color:Int):FlxGraphic {
		var rectangle:FlxGraphic = FlxGraphic.fromRectangle(width, height, color, true);
		rectangle.bitmap.fillRect(new openfl.geom.Rectangle(thickness, thickness, width - thickness * 2, height - thickness * 2), color);
		return rectangle;
	}
}