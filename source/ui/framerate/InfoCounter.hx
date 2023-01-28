package ui.framerate;

import openfl.text.TextFormat;
import openfl.display.Sprite;
import openfl.text.TextField;

import utils.ClientPrefs;
import states.MainMenuState;

class InfoCounter extends Sprite {
    public var infotxt:TextField;

    public function new() {
        super();

        infotxt = new TextField();
        
        infotxt.autoSize = LEFT;
        infotxt.x = infotxt.y = 0;
        infotxt.text = 'ALTER ${MainMenuState.alterEngineVersion} / PSYCH 0.6.3 (${Main.COMMIT_HASH.trim().substring(0, 7)})';
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