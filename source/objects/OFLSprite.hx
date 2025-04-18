package objects;

import openfl.display.Sprite;

/**
 * designed to draw a Open FL Sprite as a FlxSprite (to allow layering and auto sizing for haxe flixel cameras)
 * Custom made for Kade Engine
 */
class OFLSprite extends FlxSprite {
	public var flSprite:Sprite;

	public function new(x:Float, y:Float, width:Int, height:Int, spr:Sprite) {
		super(x, y);

		makeGraphic(width, height, FlxColor.TRANSPARENT);
		flSprite = spr;
		pixels.draw(flSprite);
	}

	var _frameCount:Int = 0;
	override function update(elapsed:Float) {
		if (_frameCount != 2) {
			pixels.draw(flSprite);
			_frameCount++;
		}
	}

	public function updateDisplay():Void {
		pixels.draw(flSprite);
	}
}