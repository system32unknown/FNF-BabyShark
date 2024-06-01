package debug.framerate;

import openfl.display.Bitmap;
import openfl.text.TextField;

class FramerateCategory extends openfl.display.Sprite {
	public var title:TextField;
	public var text:TextField;

	public var bgSprite:Bitmap;

	var _text:String = "";

	public function new(title:String, text:String = "") {
		super();

		x = 10;
		this.title = new TextField();
		this.text = new TextField();

		bgSprite = new Bitmap(Framerate.__bitmap);
		bgSprite.alpha = 0.5;
		addChild(bgSprite);

		for(label in [this.title, this.text]) {
			label.autoSize = LEFT;
			label.x = 0;
			label.y = 0;
			label.defaultTextFormat = new openfl.text.TextFormat(Framerate.fontName, label == this.title ? 16 : 15, -1);
			addChild(label);
		}
		this.title.text = title;
		this.title.multiline = this.title.wordWrap = false;
		this.text.multiline = true;

		this.text.y = this.title.y + this.title.height + 2;
	}

	public override function __enterFrame(t:Int) {
		if (alpha <= .05) return;
		super.__enterFrame(t);

		var width:Float = Math.max(this.title.width, this.text.width) + (Framerate.instance.x * 2);
		var height:Float = this.text.height + this.text.y;
		bgSprite.x = -Framerate.instance.x;
		bgSprite.scaleX = width;
		bgSprite.scaleY = height;
	}
}