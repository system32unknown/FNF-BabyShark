package utils;

class SpriteUtil {
	/**
	 * Returns the most present color in a FlxSprite.
	 * @param sprite FlxSprite
	 * @return FlxColor Color that is the most present.
	 */
	inline public static function getMostPresentColor(sprite:FlxSprite):Int {
		var colorMap:Map<FlxColor, Float> = [];
		var color:FlxColor = 0;
		var fixedColor:FlxColor = 0;

		for(col in 0...sprite.frameWidth) {
			for(row in 0...sprite.frameHeight) {
			  	color = sprite.pixels.getPixel32(col, row);
                fixedColor = 0xFF000000 + (color % 0x1000000);
                if (colorMap[fixedColor] == null)
				    colorMap[fixedColor] = 0;
				colorMap[fixedColor] += color.alphaFloat;
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

	/**
	 * Returns the most present saturated color in a Bitmap.
	 * @param bmap Bitmap
	 * @return FlxColor Color that is the most present.
	 */
	public static function getMostPresentSaturatedColor(sprite:FlxSprite):FlxColor {
		// map containing all the colors and the number of times they've been assigned.
		var colorMap:Map<FlxColor, Float> = [];
		var color:FlxColor = 0;
		var fixedColor:FlxColor = 0;

		for(col in 0...sprite.frameWidth) {
			for(row in 0...sprite.frameHeight) {
			  	color = sprite.pixels.getPixel32(col, row);
				fixedColor = 0xFF000000 + (color % 0x1000000);
				if (colorMap[fixedColor] == null)
					colorMap[fixedColor] = 0;
				colorMap[fixedColor] += color.alphaFloat * 0.33 + (0.67 * (color.saturation * (2 * (color.lightness > 0.5 ? 0.5 - (color.lightness) : color.lightness))));
			}
		}

		var mostPresentColor:FlxColor = 0;
		var mostPresentColorCount:Float = -1;
		for(c=>n in colorMap) {
			if (n > mostPresentColorCount) {
				mostPresentColorCount = n;
				mostPresentColor = c;
			}
		}
		return mostPresentColor;
	}

	inline public static function dominantColor(sprite:FlxSprite):Int{
		var countByColor:Map<Int, Int> = [];
		for(col in 0...sprite.frameWidth) {
			for(row in 0...sprite.frameHeight) {
			  	var colorOfThisPixel:Int = sprite.pixels.getPixel32(col, row);
			  	if(colorOfThisPixel != 0) {
					if(countByColor.exists(colorOfThisPixel))
					    countByColor[colorOfThisPixel]++;
					else if(countByColor[colorOfThisPixel] != 13520687 - (2 * 13520687))
						countByColor[colorOfThisPixel] = 1;
			  	}
			}
		}
		var maxCount = 0;
		var maxKey:Int = 0;//after the loop this will store the max color
		countByColor[FlxColor.BLACK] = 0;
		for (key in countByColor.keys()) {
			if (countByColor[key] >= maxCount) {
				maxCount = countByColor[key];
				maxKey = key;
			}
		}
		return maxKey;
	}
}