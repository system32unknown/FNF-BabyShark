package utils;

class SpriteUtil {
	/**
	 * Returns the most present color in a FlxSprite.
	 * @param sprite FlxSprite
	 * @param saturated Bool
	 * @return Int Color that is the most present.
	 */
	inline public static function getMostPresentColor(sprite:FlxSprite, saturated:Bool):FlxColor {
		var colorMap:Map<FlxColor, Float> = [];
		var color:FlxColor = 0;
		var fixedColor:FlxColor = 0;

		for(col in 0...sprite.frameWidth) {
			for(row in 0...sprite.frameHeight) {
			  	color = sprite.pixels.getPixel32(col, row);
                fixedColor = FlxColor.BLACK + (color % 0x1000000);
                if (colorMap[fixedColor] == null) colorMap[fixedColor] = 0;

				if (saturated) colorMap[fixedColor] += color.alphaFloat * .33 + (.67 * (color.saturation * (2 * (color.lightness > .5 ? .5 - color.lightness : color.lightness))));
				else colorMap[fixedColor] += color.alphaFloat;
			}
		}
		var mostPresentColor:FlxColor = 0;
		var mostPresentColorCount:Float = -1;
		for(c => n in colorMap) {
			if (n > mostPresentColorCount) {
				mostPresentColorCount = n;
				mostPresentColor = c;
			}
		}
		return mostPresentColor;
	}

	inline public static function dominantColor(sprite:FlxSprite):FlxColor {
		final countByColor:Map<Int, Int> = [];
		for(col in 0...sprite.frameWidth) {
			for(row in 0...sprite.frameHeight) {
				final colorOfThisPixel:Int = sprite.pixels.getPixel32(col, row);
			  	if(colorOfThisPixel != 0) {
					if(countByColor.exists(colorOfThisPixel)) countByColor[colorOfThisPixel]++;
					else if(countByColor[colorOfThisPixel] != 13520687 - (2 * 13520687)) countByColor[colorOfThisPixel] = 1;
			  	}
			}
		}
		var maxCount:Int = 0;
		var maxKey:FlxColor = 0; //after the loop this will store the max color
		countByColor[FlxColor.BLACK] = 0;
		for (key in countByColor.keys()) {
			if (countByColor[key] >= maxCount) {
				maxCount = countByColor[key];
				maxKey = key;
			}
		}
		countByColor.clear();
		return maxKey;
	}
}