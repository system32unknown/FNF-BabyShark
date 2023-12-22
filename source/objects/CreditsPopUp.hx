package objects;

import utils.MathUtil;

typedef SongHeading = {
	var path:String;
	var antiAliasing:Bool;
	var ?animation:Animation;
}

class CreditsPopUp extends FlxSpriteGroup {
	public var bg:FlxSprite;
	public var funnyText:FlxText;

	var txtFont:String;

	public function new(x:Float, y:Float, text:String, songHead:SongHeading, font:String = 'Comic Sans MS Bold') {
		super(x, y);
		add(bg = new FlxSprite().makeGraphic(400, 50, FlxColor.WHITE));
		txtFont = font;
		
		var headingPath:SongHeading = songHead;
		if (headingPath != null) {
			if (headingPath.animation == null)
				bg.loadGraphic(Paths.image(headingPath.path));
			else {
				var info = headingPath.animation;
				bg.frames = Paths.getSparrowAtlas(headingPath.path);
				bg.animation.addByPrefix(info.name, info.prefixName, info.frames, info.looped);
				bg.animation.play(info.name);
			}
			bg.antialiasing = headingPath.antiAliasing;
		}
		createHeadingText(text);

		rescaleBG();
		var yValues = MathUtil.getMinAndMax(bg.height, funnyText.height);
		funnyText.y += ((yValues[0] - yValues[1]) / 2);
	}

	public function switchHeading(newHeading:SongHeading) {
		if (bg != null) remove(bg);
		bg = new FlxSprite().makeGraphic(400, 50, FlxColor.WHITE);
		if (newHeading != null) {
			if (newHeading.animation == null)
				bg.loadGraphic(Paths.image(newHeading.path));
			else {
				var info = newHeading.animation;
				bg.frames = Paths.getSparrowAtlas(newHeading.path);
				bg.animation.addByPrefix(info.name, info.prefixName, info.frames, info.looped);
				bg.animation.play(info.name);
			}
		}
		bg.antialiasing = newHeading.antiAliasing;
		add(bg);

		rescaleBG();
	}

	public function changeText(newText:String, rescaleHeading:Bool = true) {
		createHeadingText(newText);
		if (rescaleHeading) rescaleBG();
	}

	function createHeadingText(text:String) {
		if (funnyText != null) remove(funnyText);
		funnyText = new FlxText(1, 0, 650, text, 30);
		funnyText.setFormat(txtFont, 30, FlxColor.WHITE, LEFT);
        funnyText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		funnyText.antialiasing = true;
		add(funnyText);
	}

	function rescaleBG() {
		bg.setGraphicSize(Std.int((funnyText.textField.textWidth + .5)), Std.int(funnyText.height + .5));
		bg.updateHitbox();
	}
}

class Animation {
	public var name:String;
	public var prefixName:String;
	public var frames:Int;
	public var looped:Bool;

	public function new(name:String, prefixName:String, frames:Int, looped:Bool) {
		this.name = name;
		this.prefixName = prefixName;
		this.frames = frames;
		this.looped = looped;
	}
}