package ui.framerate;

import openfl.text.TextFormat;
import openfl.display.Sprite;
import openfl.text.TextField;

import utils.ClientPrefs;

class InfoCounter extends Sprite {
    public var infotxt:TextField;

    public function new() {
        super();

        infotxt = new TextField();
        
        infotxt.autoSize = LEFT;
        infotxt.x = infotxt.y = 0;
        infotxt.text = 'ALTER 0.1 / PSYCH 0.6.3 (${Main.COMMIT_HASH})';
        infotxt.multiline = infotxt.wordWrap = false;
        infotxt.defaultTextFormat = new TextFormat(Overlay.instance.fontName, 12, -1);
        addChild(infotxt);
    }
    
    public override function __enterFrame(dt:Int) {
        if (alpha <= 0.05) return;
        super.__enterFrame(dt);

        visible = ClientPrefs.getPref('ShowWatermark');
    }
}