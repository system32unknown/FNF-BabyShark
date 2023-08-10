package openfl.text;

import openfl.text.TextField;
import openfl.text.TextFormat;

/**
 * Original Code by sayofthelor, Lore Engine.
 * Modified by altertoriel to work text colors.
 */
class BorderTextField extends TextField {
    @:noPrivateAccess final borders:Array<TextField> = new Array<TextField>();
    public var borderSize:Int = 2;

	public function new(?x:Float = 3, ?y:Float = 3, ?color:Int = 0xFFFFFFFF) {
        super();

        var defText = "0";

        this.x = x;
        width = FlxG.width;
        selectable = false;
        mouseEnabled = false;
        defaultTextFormat = new TextFormat("_sans", 12, color);
        text = defText;

        for (i in 0...8) {
            borders.push(new TextField());
            if ([0, 3, 5].contains(i)) borders[i].x = x - borderSize;
            else if ([2, 4, 7].contains(i)) borders[i].x = x + borderSize;
            else borders[i].x = x;
            borders[i].width = FlxG.width;
            borders[i].selectable = false;
            borders[i].mouseEnabled = false;
            borders[i].defaultTextFormat = new TextFormat("_sans", 12, color);
            borders[i].text = defText;
            Main.current.addChild(borders[i]);
        }
    }

    public override function setTextFormat(format:TextFormat, beginIndex:Int = -1, endIndex:Int = -1) {
        super.setTextFormat(format, beginIndex, endIndex);
        for (textborder in borders)
            textborder.setTextFormat(format, beginIndex, endIndex);
    }

    override function set_textColor(value:Int):Int @:privateAccess {
        super.set_textColor(value);
        for (textborder in borders)
            textborder.textColor = value;
        return __textFormat.color = value;
    }

    override function set_visible(value:Bool):Bool @:privateAccess {
        super.set_visible(value);
        for (textborder in borders)
            textborder.visible = value;
        return __visible = value;
    }
}