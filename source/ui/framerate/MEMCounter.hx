package ui.framerate;

import openfl.text.TextFormat;
import openfl.display.Sprite;
import openfl.text.TextField;

import utils.ClientPrefs;
import utils.MiscUtil;

class MEMCounter extends Sprite {
    public var memtxt:TextField;
    public var memPeaktxt:TextField;

    var memory:UInt = 0;
    var mempeak:UInt = 0;

    public function new() {
        super();

        memtxt = new TextField();
        memPeaktxt = new TextField();

        for (text in [memtxt, memPeaktxt]) {
            text.autoSize = LEFT;
            text.x = text.y = 0;
            text.text = "";
            text.multiline = text.wordWrap = false;
            text.defaultTextFormat = new TextFormat(Overlay.instance.fontName, 12, -1);
            addChild(text);
        }
    }

    public override function __enterFrame(dt:Int) {
        if (alpha <= 0.05) return;
        super.__enterFrame(dt);

        memory = MiscUtil.getMemoryUsage(ClientPrefs.getPref('MEMType'));
        if (memory > mempeak) mempeak = memory;
        memtxt.text = "MEM: " + MiscUtil.getInterval(memory);
        memPeaktxt.text = " / " + MiscUtil.getInterval(mempeak);

        memPeaktxt.x = memtxt.x + memtxt.width;
        visible = ClientPrefs.getPref('showMEM');
    }
}