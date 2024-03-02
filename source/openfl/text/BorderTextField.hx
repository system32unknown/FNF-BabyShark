package openfl.text;

/**
 * Original Code by sayofthelor, Lore Engine.
 * Modified by altertoriel to work text colors.
 */
class BorderTextField extends TextField {
    @:noPrivateAccess final borders:Array<TextField> = [];
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
            var otext:TextField = new TextField();
            otext.x = Math.sin(i) * borderSize;
            otext.y = Math.cos(i) * borderSize;
            otext.width = this.width;
            otext.selectable = false;
            otext.mouseEnabled = false;
            otext.defaultTextFormat = new TextFormat("_sans", 12, color);
            otext.text = defText;

            borders.push(otext);
            Main.current.addChild(otext);
        }
    }

    @:noCompletion public override function setTextFormat(format:TextFormat, beginIndex:Int = -1, endIndex:Int = -1) {
        super.setTextFormat(format, beginIndex, endIndex);
        for (textborder in borders)
            textborder.setTextFormat(format, beginIndex, endIndex);
    }

    @:noCompletion override function set_textColor(value:Int):Int @:privateAccess {
        for (textborder in borders) textborder.textColor = value;
        return super.set_textColor(value);
    }

    @:noCompletion override function set_visible(value:Bool):Bool @:privateAccess {
        for (textborder in borders) textborder.visible = value;
        return super.set_visible(value);
    }

	@:noCompletion override function set_defaultTextFormat(value:TextFormat):TextFormat {
		for (border in borders) {
			border.defaultTextFormat = value;
			border.textColor = 0xFF000000;
		}
		return super.set_defaultTextFormat(value);
	}

	@:noCompletion override function set_x(x:Float):Float {
		for (i in 0...8) borders[i].x = x + ([0, 3, 5].contains(i) ? borderSize : [2, 4, 7].contains(i) ? -borderSize : 0);
		return super.set_x(x);
	}

	@:noCompletion override function set_y(y:Float):Float {
		for (i in 0...8) borders[i].y = y + ([0, 1, 2].contains(i) ? borderSize : [5, 6, 7].contains(i) ? -borderSize : 0);
		return super.set_y(y);
	}

	@:noCompletion override function set_text(text:String):String {
		for (border in borders) border.text = text;
		return super.set_text(text);
	}
}