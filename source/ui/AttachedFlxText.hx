package ui;

import flixel.math.FlxPoint;

class AttachedFlxText extends FlxText {
	public var sprTracker:FlxSprite;
	public var textoffset:FlxPoint = new FlxPoint();

	public function new(X:Float = 0, Y:Float = 0, FieldWidth:Float = 0, ?Text:String, Size:Int = 8, EmbeddedFont:Bool = true) {
		super(X, Y, FieldWidth, Text, Size, EmbeddedFont);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (sprTracker != null) {
			setPosition(sprTracker.x + textoffset.x, sprTracker.y + textoffset.y);
			angle = sprTracker.angle;
			alpha = sprTracker.alpha;
		}
	}
}