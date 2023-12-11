package utils;

/**
 * Additional class for FlxColor lerping.
 * Gets rid of precision issues with `FlxColor.interpolate`
 */
class FlxInterpolateColor {
	public var red:Float = 0;
	public var green:Float = 0;
	public var blue:Float = 0;
	public var alpha:Float = 0;

	public var color(get, set):FlxColor;

	inline function get_color()
		return FlxColor.fromRGBFloat(red, green, blue, alpha);

	inline function set_color(c:FlxColor):FlxColor {
		red = c.redFloat;
		green = c.greenFloat;
		blue = c.blueFloat;
		alpha = c.alphaFloat;
		return c;
	}

	public inline function toString() return '[FlxInterpolateColor - (R:${red} | G:${green} | B:${blue} | A:${alpha})]';
	public function new(color:FlxColor) this.color = color;

	public function lerpTo(color:FlxColor, ratio:Float) {
		red = (color.redFloat - red) * ratio + red;
		green = (color.greenFloat - green) * ratio + green;
		blue = (color.blueFloat - blue) * ratio + blue;
		alpha = (color.alphaFloat - alpha) * ratio + alpha;
	}

	public inline function fpsLerpTo(color:FlxColor, ratio:Float)
		lerpTo(color, ratio * 60 * FlxG.elapsed);
}