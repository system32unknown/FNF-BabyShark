package ui.framerate;

import openfl.text.TextFormat;
import openfl.display.Sprite;
import openfl.text.TextField;

import utils.ClientPrefs;
import utils.MemoryUtil;
import utils.CoolUtil;

class MEMCounter extends Sprite {
    public var memtxt:TextField;
    public var __init_y:Float = 0;

    var memory:UInt = 0;
    var mempeak:UInt = 0;

    public function new() {
        super();

        memtxt = new TextField();
        
        memtxt.autoSize = LEFT;
        memtxt.x = 0;
        memtxt.y = 0;
        memtxt.text = "";
        memtxt.multiline = memtxt.wordWrap = false;
        memtxt.defaultTextFormat = new TextFormat(Overlay.instance.fontName, 12, -1);
        __init_y = memtxt.y;
        addChild(memtxt);
    }

    public override function __enterFrame(dt:Int) {
        if (alpha <= 0.05) return;
        super.__enterFrame(dt);

        memory = MemoryUtil.getMemUsage(ClientPrefs.getPref('MEMType'));
        if (memory > mempeak) mempeak = memory;
        memtxt.text = "MEM: " + MemoryUtil.getInterval(memory) + " / " + MemoryUtil.getInterval(mempeak);
        visible = ClientPrefs.getPref('showMEM');
    }
}