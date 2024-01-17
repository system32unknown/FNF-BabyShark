package objects;

class AttachedFlxText extends FlxText {
	public var sprTracker:FlxSprite;
	public var textoffset:FlxPoint = FlxPoint.get();

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (sprTracker != null) {
			setPosition(sprTracker.x + textoffset.x, sprTracker.y + textoffset.y);
			angle = sprTracker.angle;
			alpha = sprTracker.alpha;
		}
	}
}