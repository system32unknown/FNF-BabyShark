package objects;

class DepthSprite extends FlxSprite {
	public var depth:Float = 1;
	public var defaultScale:Float = 1;

	var idleAnim:String;
	public function new(image:String, x:Float = 0, y:Float = 0, ?scrollX:Float = 1, ?scrollY:Float = 1, ?animArray:Array<String> = null, ?loop:Bool = false) {
		super(x, y);

		if (animArray != null) {
			frames = Paths.getSparrowAtlas(image);
			for (i in 0...animArray.length) {
				var anim:String = animArray[i];
				animation.addByPrefix(anim, anim, 24, loop);
				if(idleAnim == null) {
					idleAnim = anim;
					animation.play(anim);
				}
			}
		} else {
			if (image != null) loadGraphic(Paths.image(image));
			active = false;
		}
		scrollFactor.set(scrollX, scrollY);
		antialiasing = ClientPrefs.data.antialiasing;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		var toScale:Float = 1 / ((cameras[0].zoom - 1) * (1 - this.depth) + 1);
		toScale = toScale * this.defaultScale;
		scale.set(toScale, toScale);
	}
}