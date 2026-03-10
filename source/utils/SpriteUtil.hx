package utils;

import flixel.graphics.FlxGraphic;
import haxe.ds.IntMap;

@:nullSafety
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

		var weights:IntMap<Float> = new IntMap<Float>();

		var bestKey:Int = 0;
		var bestWeight:Float = -1;

		for (x in 0...sprite.frameWidth) {
			for (y in 0... sprite.frameHeight) {
				var argb:Int = sprite.pixels.getPixel32(x, y);

				var a:Int = (argb >>> 24) & 0xFF;
				if (a == 0) continue; // skip fully transparent pixels

				var key:Int = 0xFF000000 | (argb & 0x00FFFFFF); // Force alpha to 0xFF, preserve RGB

				var w:Null<Float> = weights.get(key);
				if (w == null) w = 0;

				var alphaW:Float = a / 255;
				if (saturated) {
					var c:FlxColor = FlxColor.fromInt(key); // Only compute HSL if needed
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
	 * Determines the dominant (most frequently occurring) opaque colour in the
	 * current frame of a sprite.
	 *
	 * Transparent pixels (alpha < 5 %) are ignored so background fill does not
	 * skew the result. Black is also excluded because it is almost always an
	 * artefact of the sprite sheet rather than a meaningful character colour.
	 *
	 * In the event of a tie the first colour that reached the highest count wins.
	 *
	 * @param sprite The sprite whose `pixels` BitmapData will be sampled.
	 * @return The dominant colour with alpha forced to fully opaque (0xFF).
	 */
	public static function dominantColor(sprite:FlxSprite):FlxColor {
		var countByColor:Map<Int, Int> = [];

		for (col in 0...sprite.frameWidth) {
			for (row in 0...sprite.frameHeight) {
				var pixel:FlxColor = sprite.pixels.getPixel32(col, row);
				if (pixel.alphaFloat < .05) continue;

				pixel = (pixel : Int) | 0xFF000000;
				if (pixel == FlxColor.BLACK) continue;

				countByColor[pixel] = (countByColor[pixel] ?? 0) + 1;
			}
		}

		var maxCount:Int = 0;
		var dominant:FlxColor = FlxColor.BLACK; // sensible fallback if sprite is empty

		for (color => count in countByColor) {
			if (count <= maxCount) continue;
			maxCount = count;
			dominant = color;
		}

		countByColor.clear();
		return dominant;
	}

	/**
	 * Resets an FlxSprite.
	 * 
	 * @param spr Sprite to reset
	 * @param x	New X position
	 * @param y	New Y position
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

	public static function addAnimSafe(spr:FlxSprite, name:String, prefix:String, framerate:Float = 24, loop:Bool = true):Void {
		if (spr.animation.getByName(name) != null) return;

		var frames:Array<flixel.graphics.frames.FlxFrame> = [];
		@:privateAccess spr.animation.findByPrefix(frames, prefix);
		if (frames.length == 0) return;

		spr.animation.addByPrefix(name, prefix, framerate, loop);
	}
}