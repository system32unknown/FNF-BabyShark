package ui.framerate;

import openfl.text.TextFormat;
import openfl.text.TextField;

import utils.ClientPrefs;
import utils.MemoryUtil;

class MEMCounter extends TextField {
    public var __init_y:Float = 0;

    var memory:UInt = 0;
    var mempeak:UInt = 0;

    public function new() {
        super();
        
        autoSize = LEFT;
        x = 0;
        y = 0;
        text = "";
        multiline = wordWrap = false;
        defaultTextFormat = new TextFormat(Overlay.instance.fontName, 12, -1);
        __init_y = y;
    }

    public override function __enterFrame(dt:Int) {
        if (alpha <= 0.05) return;
        super.__enterFrame(dt);

        memory = MemoryUtil.getMemUsage(ClientPrefs.getPref('MEMType'));
        if (memory > mempeak) mempeak = memory;
        text = "MEM: " + MemoryUtil.getInterval(memory) + " / " + MemoryUtil.getInterval(mempeak);
        visible = ClientPrefs.getPref('showMEM');
    }
}