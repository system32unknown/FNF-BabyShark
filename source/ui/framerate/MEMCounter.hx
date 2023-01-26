package ui.framerate;

import openfl.text.TextFormat;
import openfl.display.Sprite;
import openfl.text.TextField;

import utils.ClientPrefs;
import utils.MiscUtil;

class MEMCounter extends Sprite {
    public var memtxt:TextField;

    var memory:UInt = 0;
    var mempeak:UInt = 0;

    public function new() {
        super();

        memtxt = new TextField();
        
        memtxt.autoSize = LEFT;
        memtxt.x = memtxt.y = 0;
        memtxt.text = "";
        memtxt.multiline = memtxt.wordWrap = false;
        memtxt.defaultTextFormat = new TextFormat(Overlay.instance.fontName, 12, -1);
        addChild(memtxt);
    }

    public override function __enterFrame(dt:Int) {
        if (alpha <= 0.05) return;
        super.__enterFrame(dt);

        memory = MiscUtil.getMemoryUsage(ClientPrefs.getPref('MEMType'));
        if (memory > mempeak) mempeak = memory;
        memtxt.text = "MEM: " + MiscUtil.getInterval(memory) + " / " + MiscUtil.getInterval(mempeak);
        visible = ClientPrefs.getPref('showMEM');
    }
}