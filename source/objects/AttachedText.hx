package objects;

import flixel.math.FlxPoint;

class AttachedText extends Alphabet {
	public var textoffset:FlxPoint = FlxPoint.get();
	public var sprTracker:FlxSprite;
	public var copyVisible:Bool = true;
	public var copyAlpha:Bool = false;
	public function new(text:String = "", ?offsetX:Float = 0, ?offsetY:Float = 0, ?bold = false, ?scale:Float = 1) {
		super(0, 0, text, bold);

		setScale(scale, scale);
		this.isMenuItem = false;
		this.textoffset.set(offsetX, offsetY);
	}

	override function update(elapsed:Float) {
		if (sprTracker != null) {
			setPosition(sprTracker.x + textoffset.x, sprTracker.y + textoffset.y);
			if (copyVisible) visible = sprTracker.visible;
			if (copyAlpha) alpha = sprTracker.alpha;
		}

		super.update(elapsed);
	}

	override function destroy() {
		textoffset = flixel.util.FlxDestroyUtil.put(textoffset);
		super.destroy();
	}
}