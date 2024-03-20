package substates;

import flixel.ui.FlxButton;

class Prompt extends MusicBeatSubstate {
	public var okc:Void->Void;
	public var cancelc:Void->Void;
	var theText:String = '';
	var goAnyway:Bool = false;
	var panel:FlxSprite;
	var panelbg:FlxSprite;
	var buttonAccept:FlxButton;
	var buttonNo:FlxButton;
	
	public function new(promptText:String = '', okCallback:Void->Void, cancelCallback:Void->Void, acceptOnDefault:Bool = false, option1:String = null, option2:String = null) {
		okc = okCallback;
		cancelc = cancelCallback;
		theText = promptText;
		goAnyway = acceptOnDefault;

		var op1:String = 'OK';
		var op2:String = 'CANCEL';

		if (option1 != null) op1 = option1;
		if (option2 != null) op2 = option2;

		buttonAccept = new FlxButton(473.3, 450, op1, () -> {
			if(okc != null) okc();
			close();
		});
		buttonNo = new FlxButton(633.3, 450, op2, () -> {
			if(cancelc != null) cancelc();
			close();
		});
		super();	
	}
	
	override public function create():Void {
		super.create();
		if (goAnyway) {
			if (okc != null) okc();
			close();
		} else {
			panel = new FlxSprite();
			panelbg = new FlxSprite();
			SpriteUtil.makeSelectorGraphic(panel, 300, 150, 0xff999999, 10);
			SpriteUtil.makeSelectorGraphic(panelbg, 304, 154, 0xff000000, 10);
			panel.scrollFactor.set();
			panel.screenCenter();
			panelbg.scrollFactor.set();
			panelbg.screenCenter();
			var textshit:FlxText = new FlxText(buttonNo.width * 2, panel.y, 300, theText, 16);
			textshit.alignment = CENTER;
			textshit.scrollFactor.set();
			textshit.screenCenter();
			add(panelbg);
			add(panel);
			add(buttonAccept);
			add(buttonNo);
			add(textshit);

			buttonAccept.screenCenter();
			buttonNo.screenCenter();
			buttonAccept.x -= buttonNo.width / 1.5;
			buttonAccept.y = panel.y + panel.height - 30;
			buttonNo.x += buttonNo.width / 1.5;
			buttonNo.y = panel.y + panel.height - 30;
		}
	}
}