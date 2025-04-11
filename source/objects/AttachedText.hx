package objects;

class AttachedText extends Alphabet {
	public var textoffset:FlxPoint = FlxPoint.get();
	public var sprTracker:FlxSprite;
	public var copyVisible:Bool = true;
	public var copyAlpha:Bool = false;

	public function new(text:String = "", ?offsetX:Float = 0, ?offsetY:Float = 0, ?type:AlphabetGlyphType = NORMAL, ?scale:Float = 1) {
		super(0, 0, text, type);
		this.updateScale(scale, scale);
		this.textoffset.set(offsetX, offsetY);
	}

	override function update(elapsed:Float) {
		if (sprTracker == null) {
			super.update(elapsed);
			return;
		}

		setPosition(sprTracker.x + textoffset.x, sprTracker.y + textoffset.y);
		if (copyVisible) visible = sprTracker.visible;
		if (copyAlpha) alpha = sprTracker.alpha;

		super.update(elapsed);
	}

	override function destroy() {
		textoffset.put();
		super.destroy();
	}
}