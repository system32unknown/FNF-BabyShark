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
		var colorMap:Map<FlxColor, Float> = [];
		var color:FlxColor = 0;
		var fixedColor:FlxColor = 0;

		for (col in 0...sprite.frameWidth) {
			for (row in 0...sprite.frameHeight) {
				color = sprite.pixels.getPixel32(col, row);
				fixedColor = FlxColor.BLACK + (color % 0x1000000);
				if (colorMap[fixedColor] == null) colorMap[fixedColor] = 0;

				if (saturated)
					colorMap[fixedColor] += color.alphaFloat * .33 + (.67 * (color.saturation * (2 * (color.lightness > .5 ? .5 - color.lightness : color.lightness))));
				else colorMap[fixedColor] += color.alphaFloat;
			}
		}
		var mostPresentColor:FlxColor = 0;
		var mostPresentColorCount:Float = -1;
		for (c => n in colorMap) {
			if (n > mostPresentColorCount) {
				mostPresentColorCount = n;
				mostPresentColor = c;
			}
		}
		return FlxColor.fromInt(mostPresentColor);
	}

	/**
	 * Determines the dominant color in a sprite by counting occurrences.
	 * @param sprite The sprite to analyze
	 * @return The most frequent color with full opacity
	 */
	public static function dominantColor(sprite:flixel.FlxSprite):FlxColor {
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
		spr.visible = true;
		spr.active = true;
		spr.acceleration.set();
		spr.velocity.set();
		spr.drag.set();
		spr.antialiasing = FlxSprite.defaultAntialiasing;
		FlxTween.cancelTweensOf(spr);
	}

	public static function makeOutlinedGraphic(width:Int, height:Int, Color:Int, thickness:Int, color:Int) {
		var rectangle:FlxGraphic = FlxGraphic.fromRectangle(width, height, color, true);
		rectangle.bitmap.fillRect(new openfl.geom.Rectangle(thickness, thickness, width - thickness * 2, height - thickness * 2), color);
		return rectangle;
	}
}